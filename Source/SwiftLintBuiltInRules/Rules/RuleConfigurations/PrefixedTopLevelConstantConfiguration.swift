import SwiftLintCore

@AutoApply
struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrefixedTopLevelConstantRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_private")
    private(set) var onlyPrivateMembers = false
}
