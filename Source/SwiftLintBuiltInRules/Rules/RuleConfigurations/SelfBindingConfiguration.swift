import SwiftLintCore

private enum ConfigurationKey: String {
    case severity = "severity"
    case bindIdentifier = "bind_identifier"
}

struct SelfBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = SelfBindingRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: ConfigurationKey.bindIdentifier.rawValue)
    private(set) var bindIdentifier = "self"

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        bindIdentifier = configuration[ConfigurationKey.bindIdentifier.rawValue] as? String ?? "self"
    }
}
