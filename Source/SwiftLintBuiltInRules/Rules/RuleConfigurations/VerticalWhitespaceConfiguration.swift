struct VerticalWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var maxEmptyLines = 1

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", max_empty_lines: \(maxEmptyLines)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }

        if let maxEmptyLines = configuration["max_empty_lines"] as? Int {
            self.maxEmptyLines = maxEmptyLines
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
