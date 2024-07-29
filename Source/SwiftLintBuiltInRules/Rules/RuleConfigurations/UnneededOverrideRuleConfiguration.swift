import SwiftLintCore

@AutoConfigParser
struct UnneededOverrideRuleConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = UnneededOverrideRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "affect_initializers")
    private(set) var affectInits = false
}
