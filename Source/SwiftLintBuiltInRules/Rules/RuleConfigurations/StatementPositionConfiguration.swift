enum StatementModeConfiguration: String {
    case `default` = "default"
    case uncuddledElse = "uncuddled_else"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = Self(rawValue: string) {
            self = value
        } else {
            throw Issue.unknownConfiguration
        }
    }
}

struct StatementPositionConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(statement_mode) \(statementMode.rawValue), " +
            "(severity) \(severityConfiguration.consoleDescription)"
    }

    private(set) var statementMode = StatementModeConfiguration.default
    private(set) var severityConfiguration = SeverityConfiguration.warning

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }
        if let statementModeConfiguration = configurationDict["statement_mode"] {
            try statementMode = StatementModeConfiguration(value: statementModeConfiguration)
        }
        if let severity = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: severity)
        }
    }
}
