struct TrailingWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var ignoresEmptyLines = false
    var ignoresComments = true

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", ignores_empty_lines: \(ignoresEmptyLines)" +
            ", ignores_comments: \(ignoresComments)"
    }

    init(ignoresEmptyLines: Bool, ignoresComments: Bool) {
        self.ignoresEmptyLines = ignoresEmptyLines
        self.ignoresComments = ignoresComments
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }

        ignoresEmptyLines = (configuration["ignores_empty_lines"] as? Bool == true)
        ignoresComments = (configuration["ignores_comments"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
