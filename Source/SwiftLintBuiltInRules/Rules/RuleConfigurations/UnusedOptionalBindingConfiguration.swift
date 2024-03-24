import SwiftLintCore

@AutoApply
struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = UnusedOptionalBindingRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_optional_try")
    private(set) var ignoreOptionalTry = false
}
