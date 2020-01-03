public struct FileNameConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted()), " +
            "prefixPattern: \(prefixPattern), " +
            "suffixPattern: \(suffixPattern), " +
            "nestedTypeSeparator: \(nestedTypeSeparator)"
    }

    public private(set) var severity: SeverityConfiguration
    public private(set) var excluded: Set<String>
    public private(set) var prefixPattern: String
    public private(set) var suffixPattern: String
    public private(set) var nestedTypeSeparator: String

    public init(severity: ViolationSeverity, excluded: [String] = [],
                prefixPattern: String = "", suffixPattern: String = "\\+.*", nestedTypeSeparator: String = ".") {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
        self.prefixPattern = prefixPattern
        self.suffixPattern = suffixPattern
        self.nestedTypeSeparator = nestedTypeSeparator
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
        if let nestedTypeSeparator = configurationDict["nested_type_separator"] as? String {
            self.nestedTypeSeparator = nestedTypeSeparator
        }
    }
}
