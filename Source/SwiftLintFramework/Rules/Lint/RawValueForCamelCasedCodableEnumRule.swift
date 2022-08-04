import SourceKittenFramework

public struct RawValueForCamelCasedCodableEnumRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "raw_value_for_camel_cased_codable_enum",
        name: "Raw Value For Camel Cased Codable Enum",
        description: "Camel cased cases of Codable String enums should have raw value.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            enum Numbers: Codable {
              case int(Int)
              case short(Int16)
            }
            """),
            Example("""
            enum Numbers: Int, Codable {
              case one = 1
              case two = 2
            }
            """),
            Example("""
            enum Numbers: Double, Codable {
              case one = 1.1
              case two = 2.2
            }
            """),
            Example("""
            enum Numbers: String, Codable {
              case one = "one"
              case two = "two"
            }
            """),
            Example("""
            enum Status: String, Codable {
                case OK, ACCEPTABLE
            }
            """),
            Example("""
            enum Status: String, Codable {
                case ok
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String {
                case ok
                case notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: Int, Codable {
                case ok
                case notAcceptable
                case maybeAcceptable = -1
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum Status: String, Codable {
                case ok
                case ↓notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Decodable {
               case ok
               case ↓notAcceptable
               case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Encodable {
               case ok
               case ↓notAcceptable
               case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Codable {
                case ok
                case ↓notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .enum else { return [] }

        let codableTypesSet = Set(["Codable", "Decodable", "Encodable"])
        let enumInheritedTypesSet = Set(dictionary.inheritedTypes)

        guard
            enumInheritedTypesSet.contains("String"),
            !enumInheritedTypesSet.isDisjoint(with: codableTypesSet)
        else { return [] }

        let violations = violatingOffsetsForEnum(dictionary: dictionary)
        return violations.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: SourceKittenDictionary) -> [ByteCount] {
        return substructureElements(of: dictionary, matching: .enumcase)
            .compactMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap(camelCasedEnumCasesMissingRawValue)
            .compactMap { $0.offset }
    }

    private func substructureElements(of dict: SourceKittenDictionary,
                                      matching kind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        return dict.substructure.filter { $0.declarationKind == kind }
    }

    private func camelCasedEnumCasesMissingRawValue(
        _ enumElements: [SourceKittenDictionary]) -> [SourceKittenDictionary] {
        return enumElements
            .filter { substructure in
                guard let name = substructure.name, !name.isLowercase(), !name.isUppercase() else { return false }
                return !substructure.elements.contains { $0.kind == "source.lang.swift.structure.elem.init_expr" }
            }
    }
}
