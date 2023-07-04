import SwiftLintCore

struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrefixedTopLevelConstantRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_private")
    private(set) var onlyPrivateMembers = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        onlyPrivateMembers = (configuration[$onlyPrivateMembers] as? Bool == true)

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
