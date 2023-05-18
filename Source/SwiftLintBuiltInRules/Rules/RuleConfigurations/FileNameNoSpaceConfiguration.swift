struct FileNameNoSpaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(severity) \(severityConfiguration.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) var severityConfiguration: SeverityConfiguration
    private(set) var excluded: Set<String>

    init(severity: ViolationSeverity, excluded: [String] = []) {
        self.severityConfiguration = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }

        if let severity = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: severity)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(excluded)
        }
    }
}
