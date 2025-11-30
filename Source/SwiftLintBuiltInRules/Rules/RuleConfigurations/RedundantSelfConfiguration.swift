import SwiftLintCore

@AutoConfigParser
struct RedundantSelfConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "keep_in_initializers")
    private(set) var keepInInitializers = false
}
