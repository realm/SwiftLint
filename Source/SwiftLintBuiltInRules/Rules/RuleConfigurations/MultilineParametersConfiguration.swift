import SwiftLintCore

struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = MultilineParametersRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allows_single_line")
    private(set) var allowsSingleLine = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowsSingleLine = configuration[$allowsSingleLine] as? Bool ?? true

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
