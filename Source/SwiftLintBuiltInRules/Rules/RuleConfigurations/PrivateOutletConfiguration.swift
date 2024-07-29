import SwiftLintCore

@AutoConfigParser
struct PrivateOutletConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = PrivateOutletRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_private_set")
    private(set) var allowPrivateSet = false
}
