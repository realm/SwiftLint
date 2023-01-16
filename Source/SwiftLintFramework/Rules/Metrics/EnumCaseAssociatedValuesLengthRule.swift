import SwiftSyntax

struct EnumCaseAssociatedValuesLengthRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityLevelsConfiguration(warning: 5, error: 6)

    init() {}

    static let description = RuleDescription(
        identifier: "enum_case_associated_values_count",
        name: "Enum Case Associated Values Count",
        description: "The number of associated values in an enum case should be low.",
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension EnumCaseAssociatedValuesLengthRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: SeverityLevelsConfiguration

        init(configuration: SeverityLevelsConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            guard let associatedValue = node.associatedValue,
                  case let enumCaseAssociatedValueCount = associatedValue.parameterList.count,
                  enumCaseAssociatedValueCount >= configuration.warning else {
                return
            }

            let violationSeverity: ViolationSeverity
            if let errorConfig = configuration.error,
               enumCaseAssociatedValueCount >= errorConfig {
                violationSeverity = .error
            } else {
                violationSeverity = .warning
            }

            let reason = "Enum case \(node.identifier.withoutTrivia().text) should contain "
                + "less than \(configuration.warning) associated values: "
                + "currently contains \(enumCaseAssociatedValueCount)"
            violations.append(
                ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: reason,
                    severity: violationSeverity
                )
            )
        }
    }
}
