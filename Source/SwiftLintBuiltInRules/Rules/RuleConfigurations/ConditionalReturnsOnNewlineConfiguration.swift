import SwiftLintCore

@AutoConfigParser
struct ConditionalReturnsOnNewlineConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ConditionalReturnsOnNewlineRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "if_only")
    private(set) var ifOnly = false
}
