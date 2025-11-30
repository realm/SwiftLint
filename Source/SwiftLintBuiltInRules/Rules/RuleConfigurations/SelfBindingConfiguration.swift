import SwiftLintCore

@AutoConfigParser
struct SelfBindingConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "bind_identifier")
    private(set) var bindIdentifier = "self"
}
