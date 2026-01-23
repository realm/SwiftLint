import SwiftLintCore

@AutoConfigParser
struct LargeTupleConfiguration: RuleConfiguration {
    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 2, error: 3)
    @ConfigurationElement(key: "ignore_regex")
    private(set) var ignoreRegex = false
}
