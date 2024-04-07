import SwiftLintCore

@AutoApply
struct SelfBindingConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = SelfBindingRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "bind_identifier")
    private(set) var bindIdentifier = "self"
}
