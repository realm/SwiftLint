import SwiftLintCore

struct ColonConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ColonRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "flexible_right_spacing")
    private(set) var flexibleRightSpacing = false
    @ConfigurationElement(key: "apply_to_dictionaries")
    private(set) var applyToDictionaries = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        flexibleRightSpacing = configuration[$flexibleRightSpacing] as? Bool == true
        applyToDictionaries = configuration[$applyToDictionaries] as? Bool ?? true

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
