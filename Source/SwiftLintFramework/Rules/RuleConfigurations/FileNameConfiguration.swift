public struct FileNameConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) public var severity: SeverityConfiguration
    private(set) public var excluded: Set<String>
    private(set) public var prefixPattern: String
    private(set) public var suffixPattern: String

    public init(severity: ViolationSeverity, excluded: [String] = [],
                prefixPattern: String = "", suffixPattern: String = "\\+.*") {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
        self.prefixPattern = prefixPattern
        self.suffixPattern = suffixPattern
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
        if let prefixPattern = configurationDict["prefix_pattern"] as? String {
            self.prefixPattern = prefixPattern
        }
        if let suffixPattern = configurationDict["suffix_pattern"] as? String {
            self.suffixPattern = suffixPattern
        }
    }
}
