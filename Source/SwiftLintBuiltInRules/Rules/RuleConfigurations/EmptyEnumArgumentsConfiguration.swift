import SwiftLintCore

@AutoConfigParser
struct EmptyEnumArgumentsConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded_members")
    private(set) var excludedMembers = Set<String>()
}
