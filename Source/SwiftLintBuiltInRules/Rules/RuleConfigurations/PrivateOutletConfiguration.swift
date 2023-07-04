import SwiftLintCore

struct PrivateOutletConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrivateOutletRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_private_set")
    private(set) var allowPrivateSet = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowPrivateSet = (configuration[$allowPrivateSet] as? Bool == true)

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
