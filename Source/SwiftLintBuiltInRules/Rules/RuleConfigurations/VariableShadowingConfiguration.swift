import SwiftLintCore

@AutoConfigParser
struct VariableShadowingConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_parameters")
    private(set) var ignoreParameters = true
}
