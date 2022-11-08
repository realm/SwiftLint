struct FileNameNoSpaceConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) var severity: SeverityConfiguration
    private(set) var excluded: Set<String>

    init(severity: ViolationSeverity, excluded: [String] = []) {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(excluded)
        }
    }
}
