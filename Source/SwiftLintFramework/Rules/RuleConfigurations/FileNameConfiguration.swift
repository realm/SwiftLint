public struct FileNameConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) public var severity: SeverityConfiguration
    private(set) public var excluded: Set<String>

    public init(severity: ViolationSeverity, excluded: [String] = []) {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
    }

    public mutating func apply(configuration: Any) throws {
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

public func == (lhs: FileNameConfiguration, rhs: FileNameConfiguration) -> Bool {
    return lhs.severity == rhs.severity &&
        lhs.excluded == rhs.excluded
}
