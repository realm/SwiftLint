// swiftlint:disable:next type_name
struct VerticalWhitespaceClosingBracesConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private enum ConfigurationKey: String {
        case severity = "severity"
        case onlyEnforceBeforeTrivialLines = "only_enforce_before_trivial_lines"
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var onlyEnforceBeforeTrivialLines = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", \(ConfigurationKey.onlyEnforceBeforeTrivialLines.rawValue): \(onlyEnforceBeforeTrivialLines)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }

        for (string, value) in configuration {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw Issue.unknownConfiguration
            }

            switch (key, value) {
            case (.severity, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case (.onlyEnforceBeforeTrivialLines, let boolValue as Bool):
                onlyEnforceBeforeTrivialLines = boolValue
            default:
                throw Issue.unknownConfiguration
            }
        }
    }
}
