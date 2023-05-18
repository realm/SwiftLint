struct StatementPositionConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = StatementPositionRule

    enum StatementModeConfiguration: String {
        case `default` = "default"
        case uncuddledElse = "uncuddled_else"

        init(value: Any) throws {
            if let string = (value as? String)?.lowercased(),
               let value = Self(rawValue: string) {
                self = value
            } else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }

    var consoleDescription: String {
        return "(statement_mode) \(statementMode.rawValue), " +
            "(severity) \(severityConfiguration.consoleDescription)"
    }

    private(set) var statementMode = StatementModeConfiguration.default
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        if let statementModeConfiguration = configurationDict["statement_mode"] {
            try statementMode = StatementModeConfiguration(value: statementModeConfiguration)
        }
        if let severity = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: severity)
        }
    }
}
