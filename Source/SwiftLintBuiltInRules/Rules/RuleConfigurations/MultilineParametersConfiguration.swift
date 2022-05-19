import SwiftLintCore

struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = MultilineParametersRule

    @ConfigurationElement("severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement("allows_single_line")
    private(set) var allowsSingleLine = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowsSingleLine = configuration["allows_single_line"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
