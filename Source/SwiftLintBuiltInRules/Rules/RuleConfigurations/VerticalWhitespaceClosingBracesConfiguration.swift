import SwiftLintCore

// swiftlint:disable:next type_name
struct VerticalWhitespaceClosingBracesConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = VerticalWhitespaceClosingBracesRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_enforce_before_trivial_lines")
    private(set) var onlyEnforceBeforeTrivialLines = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        for (string, value) in configuration {
            switch (string, value) {
            case ($severityConfiguration, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case ($onlyEnforceBeforeTrivialLines, let boolValue as Bool):
                onlyEnforceBeforeTrivialLines = boolValue
            default:
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }
}
