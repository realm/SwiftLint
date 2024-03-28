import SwiftLintCore

@AutoApply
struct UnneededOverrideRuleConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = UnneededOverrideRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "affect_initializers")
    private(set) var affectInits = false
}
