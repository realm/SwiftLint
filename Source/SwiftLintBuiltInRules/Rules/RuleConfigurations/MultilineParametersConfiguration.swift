import SwiftLintCore

@AutoApply
struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = MultilineParametersRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allows_single_line")
    private(set) var allowsSingleLine = true
}
