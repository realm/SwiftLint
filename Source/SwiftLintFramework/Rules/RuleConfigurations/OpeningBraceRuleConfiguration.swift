public struct OpeningBraceRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration: SeverityConfiguration

    /// If this regex matches the first line of a statement, the potential rule
    /// violations are ignored for the given statement.
    private(set) var firstLineExcludingRegex: String

    init(severity: ViolationSeverity, firstLineExcludingRegex: String) {
        self.severityConfiguration = SeverityConfiguration(severity)
        self.firstLineExcludingRegex = firstLineExcludingRegex
    }

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
        ", first_line_excluding_regex: \(firstLineExcludingRegex)"
    }

    public mutating func apply(configuration: Any) throws {
        let configurationDict = configuration as? [String: Any]

        let severityString = configuration as? String
            ?? configurationDict?["severity"] as? String

        if let severityString = severityString {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let excludingRegex = configurationDict?["first_line_excluding_regex"] as? String {
            firstLineExcludingRegex = excludingRegex
        }
    }
}
