import SwiftLintCore

@AutoConfigParser
struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_extensions")
    var validateExtensions = false
}
