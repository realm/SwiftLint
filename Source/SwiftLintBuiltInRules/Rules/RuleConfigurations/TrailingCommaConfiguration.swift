import SwiftLintCore

@AutoConfigParser
struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "mandatory_comma")
    private(set) var mandatoryComma = false
}
