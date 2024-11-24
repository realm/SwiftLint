import SwiftLintCore

@AutoConfigParser
struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = MultilineParametersRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allows_single_line")
    private(set) var allowsSingleLine = true
    @ConfigurationElement(key: "max_number_of_single_line_parameters")
    private(set) var maxNumberOfSingleLineParameters: Int?

    func validate() throws {
        guard let maxNumberOfSingleLineParameters else {
            return
        }
        guard maxNumberOfSingleLineParameters >= 1 else {
            Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: "Option '\($maxNumberOfSingleLineParameters.key)' should be >= 1."
            ).print()
            return
        }

        if maxNumberOfSingleLineParameters > 1, !allowsSingleLine {
            Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: """
                         Option '\($maxNumberOfSingleLineParameters.key)' has no effect when \
                         '\($allowsSingleLine.key)' is false.
                         """
            ).print()
        }
    }
}
