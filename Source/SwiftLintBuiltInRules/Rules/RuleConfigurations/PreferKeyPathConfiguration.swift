import SwiftLintCore

@AutoConfigParser
struct PreferKeyPathConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "restrict_to_standard_functions")
    private(set) var restrictToStandardFunctions = true
    @ConfigurationElement(key: "ignore_identity_closures")
    private(set) var ignoreIdentityClosures = false
}
