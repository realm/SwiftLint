import SwiftLintCore

private enum ConfigurationKey: String {
    case severity = "severity"
    case allowMultilineFunc = "allow_multiline_func"
}

struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OpeningBraceRule

    @ConfigurationElement(ConfigurationKey.severity.rawValue)
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(ConfigurationKey.allowMultilineFunc.rawValue)
    private(set) var allowMultilineFunc = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        allowMultilineFunc = configuration[ConfigurationKey.allowMultilineFunc.rawValue] as? Bool ?? false
    }
}
