import SourceKittenFramework

public struct ExplicitEnumRawValueRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_enum_raw_value",
        name: "Explicit Enum Raw Value",
        description: "Enums should be explicitly assigned their raw values.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            enum Numbers {
              case int(Int)
              case short(Int16)
            }
            """,
            """
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """,
            """
            enum Numbers: Double {
              case one = 1.1
              case two = 2.2
            }
            """,
            """
            enum Numbers: String {
              case one = "one"
              case two = "two"
            }
            """,
            """
            protocol Algebra {}
            enum Numbers: Algebra {
              case one
            }
            """
        ],
        triggeringExamples: [
            """
            enum Numbers: Int {
              case one = 10, ↓two, three = 30
            }
            """,
            """
            enum Numbers: NSInteger {
              case ↓one
            }
            """,
            """
            enum Numbers: String {
              case ↓one
              case ↓two
            }
            """,
            """
            enum Numbers: String {
               case ↓one, two = "two"
            }
            """,
            """
            enum Numbers: Decimal {
              case ↓one, ↓two
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
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
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: [String: SourceKitRepresentable]) -> [Int] {
        let locs = substructureElements(of: dictionary, matching: .enumcase)
            .compactMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap(enumElementsMissingInitExpr)
            .compactMap { $0.offset }

        return locs
    }

    private func substructureElements(of dict: [String: SourceKitRepresentable],
                                      matching kind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {
        return dict.substructure
            .filter { $0.kind.flatMap(SwiftDeclarationKind.init) == kind }
    }

    private func enumElementsMissingInitExpr(
        _ enumElements: [[String: SourceKitRepresentable]]) -> [[String: SourceKitRepresentable]] {
        return enumElements
            .filter { !$0.elements.contains { $0.kind == "source.lang.swift.structure.elem.init_expr" } }
    }
}
