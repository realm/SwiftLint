import Foundation
import SourceKittenFramework

public struct NoReturnVoidRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_return_void",
        name: "No  Return Void",
        description: "No expressions after return in void functions.",
        kind: .style,
        nonTriggeringExamples: [
            "",
            "func test() {}",
            """
            init?() {
                guard condition else {
                    return nil
                }
            }
            """,
            """
            init?(arg: String?) {
                guard arg != nil else {
                    return nil
                }
            }
            """,
            """
            func test() {
                guard condition else {
                    return
                }
            }
            """,
            """
            func test() -> Result<String, Error> {
                func other() {}
                func otherVoid() -> Void {}
            }
            """,
            """
            func test() {
                if bar {
                    print("")
                    return
                }

                let foo = [1, 2, 3].filter { return true }
                return
            }
            """,
            """
            func test() {
                guard foo else {
                    bar()
                    return
                }
            }
            """
        ],
        triggeringExamples: [
            """
            func initThing() {
                guard foo else {
                    return↓ print("")
                }
            }
            """,
            """
            // Leading comment
            func test() {
                guard condition else {
                    return↓ assertionfailure("")
                }
            }
            """,
            """
            func test() -> Result<String, Error> {
                func other() {
                    guard false else {
                        return↓ assertionfailure("")
                    }
                }
                func otherVoid() -> Void {}
            }
            """,
            """
            func test() {
                guard conditionIsTrue else {
                    sideEffects()
                    return // comment
                }
                guard otherCondition else {
                    return↓ assertionfailure("")
                }
                differentSideEffect()
            }
            """,
            """
            func test() {
                guard otherCondition else {
                    return↓ assertionfailure(""); // comment
                }
                differentSideEffect()
            }
            """,
            """
            func test() {
              if x {
                return↓ foo()
              }
              bar()
            }
            """,
            """
            func test() {
              switch x {
                case .a:
                  return↓ foo() // return to skip baz()
                case .b:
                  bar()
              }
              baz()
            }
            """,
            """
            func test() {
              if check {
                if otherCheck {
                  return↓ foo()
                }
              }
              bar()
            }
            """,
            """
            func test() {
                return↓ foo()
            }
            """,
            """
            func test() {
              return foo({
                return bar()
              })
              return↓ foo()
            }
            """,
            """
            func test() {
              guard x else {
                return↓ foo()
              }
              bar()
            }
            """,
            """
            func test() {
              let closure: () -> () = {
                return assert()
              }
              if check {
                if otherCheck {
                  return // comments are fine
                }
              }
              return↓ foo()
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            dictionary.isVoid(),
            !dictionary.isInit(),
            let bodyRange = dictionary.byteRange()
        else {
            return []
        }

        let statementRanges = dictionary.statementRanges()
        var bodyRangeAfterLastStatement = bodyRange

        if let lastStatement = statementRanges?.last {
            bodyRangeAfterLastStatement.location = lastStatement.upperBound
        }

        let ranges: [NSRange] = [bodyRangeAfterLastStatement] + (statementRanges ?? [])

        return ranges
            .map({ range in
                return file.syntaxMap.tokens.filter { range.contains($0.offset) && !$0.isComment }
            })
            .compactMap({ tokens in
                guard let last = tokens.last,
                    let lastReturn = tokens.last(where: { $0.isReturnKeyword(in: file) }),
                    last != lastReturn
                else {
                    return nil
                }

                let location = Location(file: file, byteOffset: lastReturn.offset + lastReturn.length)
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: location)
            })
    }
}

private extension Dictionary where Dictionary == [String: SourceKitRepresentable] {
    func isVoid() -> Bool {
        return self["key.typename"] == nil || (self["key.typename"] as? String) == "Void"
    }

    func isInit() -> Bool {
        return (self["key.name"] as? String)?.hasPrefix("init(") ?? false
    }

    func statementRanges() -> [NSRange]? {
        let ranges = (self["key.substructure"] as? [[String: SourceKitRepresentable]])?
            .compactMap { $0 }
            .filter { $0.isStatement() }
            .compactMap { $0.byteRange() }

        return ranges
    }

    func isStatement() -> Bool {
        return (self["key.kind"] as? String)?.starts(with: "source.lang.swift.stmt") == true
    }

    func byteRange() -> NSRange? {
        guard let offset = self["key.offset"] as? Int64, let length = self["key.length"] as? Int64 else {
            return nil
        }

        return NSRange(location: Int(offset), length: Int(length))
    }
}

private extension SyntaxToken {
    var isComment: Bool {
        return self.type == "source.lang.swift.syntaxtype.comment"
    }

    var isKeyword: Bool {
        return self.type == "source.lang.swift.syntaxtype.keyword"
    }

    func isReturnKeyword(in file: File) -> Bool {
        return self.isKeyword && (file.contents(for: self) == "return")
    }
}
