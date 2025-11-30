import SwiftLintCore

@AutoConfigParser
struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_optional_try")
    private(set) var ignoreOptionalTry = false
}
