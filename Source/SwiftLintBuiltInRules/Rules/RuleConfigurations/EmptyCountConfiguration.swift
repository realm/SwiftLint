import SwiftLintCore

private enum ConfigurationKey: String {
    case severity = "severity"
    case onlyAfterDot = "only_after_dot"
}

struct EmptyCountConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = EmptyCountRule

    @ConfigurationElement(ConfigurationKey.severity.rawValue)
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.error)
    @ConfigurationElement(ConfigurationKey.onlyAfterDot.rawValue)
    private(set) var onlyAfterDot = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        onlyAfterDot = configuration[ConfigurationKey.onlyAfterDot.rawValue] as? Bool ?? false
    }
}
