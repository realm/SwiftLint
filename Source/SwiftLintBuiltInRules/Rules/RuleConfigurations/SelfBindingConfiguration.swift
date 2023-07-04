import SwiftLintCore

struct SelfBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = SelfBindingRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "bind_identifier")
    private(set) var bindIdentifier = "self"

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        bindIdentifier = configuration[$bindIdentifier] as? String ?? "self"
    }
}
