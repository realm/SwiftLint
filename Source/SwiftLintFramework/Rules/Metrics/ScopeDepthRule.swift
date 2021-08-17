import SourceKittenFramework

public struct ScopeDepthRule: ConfigurationProviderRule {
    public var configuration = ScopeDepthConfiguration(warningDepth: 7, errorDepth: 10)

    public init() {}

    public static let description = RuleDescription(
        identifier: "scope_depth",
        name: "Scope Depth",
        description: "Code should not be more than 10 scope levels deep",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("struct F0 { }"),
            Example("struct F0 { struct F1 {}}"),
            Example("struct F0 { struct F1 { struct F2 { Struct F3 { struct F4 {}}}}}"),
            Example("struct F0 { struct F1 { struct F2 { Struct F3 { struct F4 { struct F5 { struct F6 { struct F7 {}}}}}}}}"), // swiftlint:disable:this line_length
            Example("""
                class One {
                  class Two {
                    class Three {
                      func whatever() {}
                      func four() {
                        if 5 == 5 {
                          print("Irrelevant")
                          repeat {
                            if 7 == 7 {
                              print("Safe")
                            }
                          } while 6 == 6
                        } else {
                          print("Safe")
                        }
                      }
                    }
                  }
                }
                """)
        ],
        triggeringExamples: [
            Example("struct F0 { struct F1 { struct F2 { Struct F3 { struct F4 { struct F5 { struct F6 { struct F7 { ↓struct F8 { ↓struct F9 { ↓struct F10 { ↓struct F11 {}}}}}}}}}}}}"), // swiftlint:disable:this line_length
            Example("struct F0 { struct F1 { struct F2 { Struct F3 { struct F4 { struct F5 { struct F6 { struct F7 { ↓struct F8 { ↓struct F9 { ↓struct F10 { ↓struct F11 { struct F12 {}}}}}}}}}}}}}"), // swiftlint:disable:this line_length
            Example("""
                class Zero {
                  class One {
                    class Two {
                      func safeFunc() { print("Safe") }
                      func three() {
                        if 4 == 4 {
                          repeat {
                            guard 7 == 7 else {
                              break
                            }
                            if 6 != 6 {
                              print("Safe")
                            }
                            if 6 == 6 {
                              print("Pre-call")
                              callFunc() {
                                ↓print("Eight")
                                ↓if 8 == 8 ↓{
                                  ↓print("Nine")
                                  ↓if 9 == 9 ↓{
                                    ↓if 10 == 10 ↓{
                                      ↓{
                                        print("Bad")
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          } while 5 == 5
                        } else {
                          print("Safe")
                        }
                      }
                    }
                  }
                }
                """),
            Example("""
                class Zero {
                  class One {
                    class Two {
                      func three() {
                        switch 4 {
                        case 4:
                          for i in x {
                            for var i = 0; i < 10; i++ {
                              ↓callFunc() ↓↓{
                                ↓while true ↓{
                                  ↓if 1 == 2 ↓{
                                    ↓{
                                      print("Bad")
                                    }
                                  }
                                }
                                ↓print("Ten")
                              }
                              ↓print("Post-call")
                            }
                          }
                        default:
                          break
                      }
                      func safeFunc1() { let x = [1,2,3] }
                      func safeFunc2(a: Int) { let x = [1: "One", 2: "Two", 3: "Three", a: "Unknown"] }
                      func safeFunc3() { let x = (1, 2) }
                      func safeFunc4() { let x = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
                    }
                  }
                }
                """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let substructure = file.structureDictionary.substructure

        var violations = [StyleViolation]()

        for structure in substructure {
            // This will give all structures and depths in the file, so we filter
            // down to just the ones we care about
            for (depth, structureReference) in determineStructureDepths(structure) {
                guard depth > self.configuration.warningDepth else {
                    continue
                }

                violations.append(
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: depth > self.configuration.errorDepth ? .error : .warning,
                        location: Location(file: file, byteOffset: structureReference.offset ?? 0),
                        reason: "Exceeds configured scope depth: \(configuration.consoleDescription)"
                    )
                )
            }
        }
        return violations
    }

    private func determineStructureDepths(
        _ structure: SwiftLintFramework.SourceKittenDictionary, depth: Int = 0
    ) -> [(Int, SourceKittenDictionary)] {
        var results = [(Int, SourceKittenDictionary)]()

        results.append((depth, structure))

        guard !structure.substructure.isEmpty else {
            return results
        }

        // There's no point going deeper than we have to. If somthing is too
        // deep, then obviously everything deeper will also need to be corrected.
        guard depth <= configuration.errorDepth else {
            return results
        }

        // Determine if we should increase the scope level or not
        let shouldIncreaseScope: Bool = {
            // If it was an expression it doesn't change the depth
            if structure.expressionKind != nil {
                return false
            }

            // If it was a declaration, it depends on the type of declaration
            if let declarationKind: SwiftDeclarationKind = structure.declarationKind {
                switch declarationKind {
                case .`associatedtype`, .enumcase, .enumelement, .genericTypeParam,
                     .module, .`typealias`, .varClass, .varGlobal, .varInstance,
                     .varLocal, .varParameter, .varStatic:
                  return false
                case .`class`, .`enum`, .`extension`, .extensionClass, .extensionEnum,
                     .extensionProtocol, .extensionStruct, .functionAccessorAddress,
                     .functionAccessorDidset, .functionAccessorGetter, .functionAccessorModify,
                     .functionAccessorMutableaddress, .functionAccessorRead, .functionAccessorSetter,
                     .functionAccessorWillset, .functionConstructor, .functionDestructor,
                     .functionFree, .functionMethodClass, .functionMethodInstance,
                     .functionMethodStatic, .functionOperator, .functionOperatorInfix,
                     .functionOperatorPostfix, .functionOperatorPrefix, .functionSubscript,
                     .opaqueType, .precedenceGroup, .`protocol`, .`struct`:
                  return true
                }
            }

            // Statements usually increase scope/depth. For anything with a
            // brace block though we just let the braces handle it (since they
            // are separate from the statement).
            if let statementKind = structure.statementKind {
                switch statementKind {
                case .brace, .`switch`, .`case`:
                    return true
                case .forEach, .`if`, .repeatWhile, .`guard`, .`while`, .`for`:
                    return false
                }
            }

            return false
        }()

        for substructure in structure.substructure {
            let newDepth = shouldIncreaseScope ? depth + 1 : depth
            results.append(contentsOf: determineStructureDepths(substructure, depth: newDepth))
        }
        return results
    }
}
