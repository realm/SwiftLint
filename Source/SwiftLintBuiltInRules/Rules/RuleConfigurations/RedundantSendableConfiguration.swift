import SwiftLintCore

@AutoConfigParser
struct RedundantSendableConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantSendableRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "global_actors")
    private(set) var globalActors = Set<String>()
}
