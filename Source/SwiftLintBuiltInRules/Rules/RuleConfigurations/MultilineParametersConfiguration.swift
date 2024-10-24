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
        if let maxNumberOfSingleLineParameters, !allowsSingleLine && maxNumberOfSingleLineParameters > 1 {
            throw Issue.invalidConfiguration(
                ruleID: Parent.identifier,
                message: """
                         Invalid configuration: 'allows_single_line' and 'max_number_of_single_line_parameters' are mutually exclusive.
                         They cannot both be active with conflicting values.
                         """
            )
        }
    }
}
