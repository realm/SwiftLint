import SwiftLintCore

@AutoApply
struct ConditionalReturnsOnNewlineConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ConditionalReturnsOnNewlineRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "if_only")
    private(set) var ifOnly = false
}
