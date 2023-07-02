import SwiftLintCore

struct ColonConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ColonRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "flexible_right_spacing")
    private(set) var flexibleRightSpacing = false
    @ConfigurationElement(key: "apply_to_dictionaries")
    private(set) var applyToDictionaries = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        flexibleRightSpacing = configuration["flexible_right_spacing"] as? Bool == true
        applyToDictionaries = configuration["apply_to_dictionaries"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
