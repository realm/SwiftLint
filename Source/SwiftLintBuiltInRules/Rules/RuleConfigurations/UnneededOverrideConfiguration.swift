import SwiftLintCore

@AutoConfigParser
struct UnneededOverrideConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "affect_initializers")
    private(set) var affectInits = false
    @ConfigurationElement(key: "excluded_methods")
    private(set) var excludedMethods = Set<String>()
}
