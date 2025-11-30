import SwiftLintCore

@AutoConfigParser
struct EmptyCountConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.error)
    @ConfigurationElement(key: "only_after_dot")
    private(set) var onlyAfterDot = false
}
