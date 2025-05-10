import SwiftLintCore

@AutoConfigParser
struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = PrefixedTopLevelConstantRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_private")
    private(set) var onlyPrivateMembers = false
}
