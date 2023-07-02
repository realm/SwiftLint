import SwiftLintCore

struct ConditionalReturnsOnNewlineConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ConditionalReturnsOnNewlineRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "if_only")
    private(set) var ifOnly = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        ifOnly = configuration["if_only"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
