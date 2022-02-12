import SourceKittenFramework

public struct MutableHashRule: ASTRule, AutomaticTestableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mutable_hash",
        name: "Mutable Hash",
        description: "Using of mutable property as a hash value might violate Hashable protocol requirements.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                    class NonHashableClass {
                      var mutableProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(mutableProperty)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      let immutableProperty: Int = 42
                      weak var mutableProperty: AnyObject?
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(immutableProperty)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      static let staticImmutableProperty: Int = 42
                      static var staticMutableProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(Self.staticImmutableProperty)
                      }
                    }
                    """),
            Example("""
                    struct NonHashableStruct {
                      weak var weakMutableProperty: AnyObject?
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      var mutableProperty: Int = 42
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      var mutableProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(self.mutableProperty)
                      }
                    }
                    """)
        ],
        triggeringExamples: [
            Example("""
                    class HashableClass: Hashable {
                      class var mutableClassProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(-3*(HashableClass.↓mutableClassProperty+5))
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      weak var mutableProperty: AnyObject?
                      func hash(into h: inout Hasher) {
                        h.combine(self.↓mutableProperty!.pointerValue)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      weak var mutableProperty: AnyObject?
                      func hash(into hasher: inout Hasher) {
                        self.↓mutableProperty?.pointerValue?.hash(into: &hasher)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      static var mutableStaticProperty: [Int] = [42]
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(Self.↓mutableStaticProperty[0])
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      static var mutableStaticProperty: Int = 42
                      func hash(into h: inout Hasher) {
                        Self.↓mutableStaticProperty!.pointerValue?.hash(into: &h)
                      }
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      let immutableProperty: Int = 42
                      weak ↓var weakMutableProperty: AnyObject?
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      let immutableProperty: Int = 42
                      weak var weakMutableProperty: AnyObject?
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(self.immutableProperty)
                        hasher.combine(self.↓weakMutableProperty)
                      }
                    }
                    """)
        ])

    public func validate(
        file: SwiftLintFile, kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .class || kind == .struct, dictionary.inheritedTypes.contains("Hashable") else {
            return []
        }

        guard let hashMethod = dictionary.substructure.first(where: \.isHashIntoMethod) else {
            if kind == .struct {
                return dictionary.substructure.lazy.filter(\.isMutableWeakProperty).compactMap {
                    if let offset = $0.offset {
                        return StyleViolation(
                            ruleDescription: Self.description,
                            severity: configuration.severity,
                            location: Location(file: file, byteOffset: offset))
                    }

                    return nil
                }
            }

            return []
        }

        let hashMethodSubstructure = hashMethod.substructure.lazy
        guard let typeName = dictionary.name,
            let hasherParameterName = hashMethodSubstructure.first(where: \.isParameter)?.name else {
            return []
        }

        let callParser = CallParser(file, parentTypeName: typeName)
        let mutableProperties: Set<String>
        if kind == .struct {
            mutableProperties = Set(dictionary.substructure.lazy.filter(\.isMutableWeakProperty).compactMap(\.name))
        } else {
            mutableProperties = Set(dictionary.substructure.lazy.filter(\.isMutableProperty).compactMap(\.name))
        }

        let arguments = hashMethodSubstructure
            .filter({ $0.isCombineCall(instanceName: hasherParameterName) }).compactMap(callParser.parseArgument(from:))
        let calls = hashMethodSubstructure.filter(\.isHashIntoCall).compactMap(callParser.parseCallChain(from:))
        return [arguments, calls].joined().filter({ mutableProperties.contains($0.name) }).map {
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: $0.offset))
        }
    }
}

private extension SourceKittenDictionary {
    func isCombineCall(instanceName: String) -> Bool {
        expressionKind == .call && name == "\(instanceName).combine"
    }

    var isHashIntoCall: Bool {
        expressionKind == .call
            && name?.hasSuffix("hash") ?? false
            && substructure.count == 1
            && substructure.first?.expressionKind == .argument
            && substructure.first?.name == "into"
    }

    var isHashIntoMethod: Bool {
        declarationKind == .functionMethodInstance && name == "hash(into:)"
    }

    var isMutableProperty: Bool {
        (declarationKind == .varClass || declarationKind == .varInstance || declarationKind == .varStatic)
            && value["key.setter_accessibility"] != nil
    }

    var isMutableWeakProperty: Bool {
        isMutableProperty && enclosedSwiftAttributes.contains(.weak)
    }

    var isParameter: Bool {
        declarationKind == .varParameter
    }
}

private struct CallParser {
    private let file: SwiftLintFile
    private let parentTypeName: String

    init(_ file: SwiftLintFile, parentTypeName: String) {
        self.file = file
        self.parentTypeName = parentTypeName
    }

    func parseArgument(from substructure: SourceKittenDictionary) -> (name: String, offset: ByteCount)? {
        // for some reason there are no arguments in the call substructure, so extracting the whole body from the file
        if let bodyRange = substructure.bodyByteRange {
            return parseProperty(from: bodyRange)
        }

        return nil
    }

    func parseCallChain(from substructure: SourceKittenDictionary) -> (name: String, offset: ByteCount)? {
        if let nameRange = substructure.nameByteRange {
            return parseProperty(from: nameRange)
        }

        return nil
    }

    private func parseProperty(from range: ByteRange) -> (name: String, offset: ByteCount)? {
        // property should be the first identifier in the expression,
        // class/static property might be preceded by the type name identifier
        let stringView = file.stringView
        return file.syntaxMap.tokens(inByteRange: range).lazy.compactMap({
            if $0.kind == .identifier, let name = stringView.substringWithByteRange($0.range), name != parentTypeName {
                return (name, $0.range.location)
            }

            return nil
        }).first
    }
}
