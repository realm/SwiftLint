import SwiftLintCore

@AutoApply
struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedOptionalBindingRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_optional_try")
    private(set) var ignoreOptionalTry = false
}
