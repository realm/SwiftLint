import SourceKittenFramework

public struct ExplicitEnumRawValueRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_enum_raw_value",
        name: "Explicit Enum Raw Value",
        description: "Enums should be explicitly assigned their raw values.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            enum Numbers {
              case int(Int)
              case short(Int16)
            }
            """),
            Example("""
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """),
            Example("""
            enum Numbers: Double {
              case one = 1.1
              case two = 2.2
            }
            """),
            Example("""
            enum Numbers: String {
              case one = "one"
              case two = "two"
            }
            """),
            Example("""
            protocol Algebra {}
            enum Numbers: Algebra {
              case one
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum Numbers: Int {
              case one = 10, ↓two, three = 30
            }
            """),
            Example("""
            enum Numbers: NSInteger {
              case ↓one
            }
            """),
            Example("""
            enum Numbers: String {
              case ↓one
              case ↓two
            }
            """),
            Example("""
            enum Numbers: String {
               case ↓one, two = "two"
            }
            """),
            Example("""
            enum Numbers: Decimal {
              case ↓one, ↓two
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        // Check if it's an enum which supports raw values
        let implicitRawValueSet: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Float80", "Decimal", "NSNumber",
            "NSDecimalNumber", "NSInteger", "String"
        ]

        let enumInheritedTypesSet = Set(dictionary.inheritedTypes)

        guard !implicitRawValueSet.isDisjoint(with: enumInheritedTypesSet) else {
            return []
        }

        let violations = violatingOffsetsForEnum(dictionary: dictionary)
        return violations.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: SourceKittenDictionary) -> [ByteCount] {
        let locs = substructureElements(of: dictionary, matching: .enumcase)
            .compactMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap(enumElementsMissingInitExpr)
            .compactMap { $0.offset }

        return locs
    }

    private func substructureElements(of dict: SourceKittenDictionary,
                                      matching kind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        return dict.substructure
            .filter { $0.declarationKind == kind }
    }

    private func enumElementsMissingInitExpr(
        _ enumElements: [SourceKittenDictionary]) -> [SourceKittenDictionary] {
        return enumElements
            .filter { !$0.elements.contains { $0.kind == "source.lang.swift.structure.elem.init_expr" } }
    }
}
