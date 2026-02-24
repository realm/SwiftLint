import SwiftLintCore

@AutoConfigParser
struct UnusedParameterConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_underscore_prefixed_names")
    private(set) var allowUnderscorePrefixedNames = false
}
