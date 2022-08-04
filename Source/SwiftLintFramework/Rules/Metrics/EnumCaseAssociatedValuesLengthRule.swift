import SourceKittenFramework

public struct EnumCaseAssociatedValuesLengthRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 5, error: 6)

    public init() {}

    public static let description = RuleDescription(
        identifier: "enum_case_associated_values_count",
        name: "Enum Case Associated Values Count",
        description: "Number of associated values in an enum case should be low",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("""
            enum Employee {
                case fullTime(name: String, retirement: Date, designation: String, contactNumber: Int)
                case partTime(name: String, age: Int, contractEndDate: Date)
            }
            """),
            Example("""
            enum Barcode {
                case upc(Int, Int, Int, Int)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum Employee {
                case ↓fullTime(name: String, retirement: Date, age: Int, designation: String, contactNumber: Int)
                case ↓partTime(name: String, contractEndDate: Date, age: Int, designation: String, contactNumber: Int)
            }
            """),
            Example("""
            enum Barcode {
                case ↓upc(Int, Int, Int, Int, Int, Int)
            }
            """)
        ]
    )

    public func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard kind == .enumelement,
            let keyOffset = dictionary.offset,
            let keyName = dictionary.name,
            let caseNameWithoutParams = keyName.split(separator: "(").first else {
            return []
        }

        var violations: [StyleViolation] = []

        let enumCaseAssociatedValueCount = keyName.split(separator: ":").count - 1

        if enumCaseAssociatedValueCount >= configuration.warning {
            let violationSeverity: ViolationSeverity

            if let errorConfig = configuration.error,
                enumCaseAssociatedValueCount >= errorConfig {
                violationSeverity = .error
            } else {
                violationSeverity = .warning
            }

            let reason = "Enum case \(caseNameWithoutParams) should contain "
                + "less than \(configuration.warning) associated values: "
                + "currently contains \(enumCaseAssociatedValueCount)"
            violations.append(
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: violationSeverity,
                    location: Location(file: file, byteOffset: keyOffset),
                    reason: reason
                )
            )
        }
        return violations
    }
}
