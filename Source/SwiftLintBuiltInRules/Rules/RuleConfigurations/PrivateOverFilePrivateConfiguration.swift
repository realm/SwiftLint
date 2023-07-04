import SwiftLintCore

struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrivateOverFilePrivateRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_extensions")
    var validateExtensions = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        validateExtensions = configuration[$validateExtensions] as? Bool ?? false
    }
}
