import SwiftLintCore

@AutoConfigParser
struct SortedCollectionMembersConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "reverse")
    private(set) var reverse = false
}
