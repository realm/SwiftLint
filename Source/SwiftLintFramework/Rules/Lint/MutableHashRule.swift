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
                    struct HashableStruct: Hashable {
                      let mutableProperty: Int = 42
                    }
                    """)
        ],
        triggeringExamples: [
            Example("""
                    class HashableClass: Hashable {
                      class var mutableClassProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(↓HashableClass.mutableClassProperty)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      weak var mutableProperty: AnyObject?
                      func hash(into h: inout Hasher) {
                        h.combine(↓self.mutableProperty!.pointerValue)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      weak var mutableProperty: AnyObject?
                      func hash(into hasher: inout Hasher) {
                        ↓self.mutableProperty?.pointerValue?.hash(into: &hasher)
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      static var mutableStaticProperty: [Int] = [42]
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(↓Self.mutableStaticProperty[0])
                      }
                    }
                    """),
            Example("""
                    class HashableClass: Hashable {
                      static var mutableStaticProperty: Int = 42
                      func hash(into h: inout Hasher) {
                        ↓Self.mutableStaticProperty!.pointerValue?.hash(into: &h)
                      }
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      ↓var mutableProperty: Int = 42
                    }
                    """),
            Example("""
                    struct HashableStruct: Hashable {
                      var mutableProperty: Int = 42
                      func hash(into hasher: inout Hasher) {
                        hasher.combine(↓(-self.mutableProperty)*3)
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
                let mutableProperties = dictionary.substructure.lazy.filter(\.isMutableProperty)
                if mutableProperties.isNotEmpty {
                    return mutableProperties.compactMap {
                        if let offset = $0.offset {
                            return StyleViolation(
                                ruleDescription: Self.description,
                                severity: configuration.severity,
                                location: Location(file: file, byteOffset: offset))
                        }

                        return nil
                    }
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
        let mutableProperties = Set(dictionary.substructure.lazy.filter(\.isMutableProperty).compactMap(\.name))
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

    var isParameter: Bool {
        declarationKind == .varParameter
    }
}

private struct CallParser {
    private static let callChainSeparators: Set<Character> =
        [".", "?", "!", " ", "[", "(", ")", "&", "|", "^", "+", "-", "*", "/", "%", "<", ">", "="]
    private let file: SwiftLintFile
    private let ignoredNames: Set<String>

    init(_ file: SwiftLintFile, parentTypeName: String) {
        self.file = file
        ignoredNames = ["self", "Self", parentTypeName]
    }

    func parseArgument(from substructure: SourceKittenDictionary) -> (name: String, offset: ByteCount)? {
        // for some reason there are no arguments in the call substructure, so extracting the whole body from the file
        if let bodyRange = substructure.bodyByteRange,
            let argumentExpression = file.stringView.substringWithByteRange(bodyRange),
            let bodyOffset = substructure.bodyOffset {
            return (parsePropertyName(from: argumentExpression), bodyOffset)
        }

        return nil
    }

    func parseCallChain(from substructure: SourceKittenDictionary) -> (name: String, offset: ByteCount)? {
        if let callExpression = substructure.name, let offset = substructure.offset {
            return (parsePropertyName(from: callExpression), offset)
        }

        return nil
    }

    private func parsePropertyName(from expression: String) -> String {
        // result name should be in left part of the expression, it might be preceded by `self`, `Self` or type name
        let expressionParts = expression.split(maxSplits: 2, whereSeparator: Self.callChainSeparators.contains)
        if expressionParts.count > 1 {
            var propertyName = String(expressionParts[0])
            if ignoredNames.contains(propertyName) {
                propertyName = String(expressionParts[1])
            }

            return propertyName
        }

        return expression
    }
}
