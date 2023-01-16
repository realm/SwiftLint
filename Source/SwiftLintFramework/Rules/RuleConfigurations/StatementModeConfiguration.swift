enum StatementModeConfiguration: String {
    case `default` = "default"
    case uncuddledElse = "uncuddled_else"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = Self(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}

struct StatementConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(statement_mode) \(statementMode.rawValue), " +
            "(severity) \(severity.consoleDescription)"
    }

    var statementMode: StatementModeConfiguration
    var severity: SeverityConfiguration

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        if let statementModeConfiguration = configurationDict["statement_mode"] {
            try statementMode = StatementModeConfiguration(value: statementModeConfiguration)
        }
        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }
    }
}
