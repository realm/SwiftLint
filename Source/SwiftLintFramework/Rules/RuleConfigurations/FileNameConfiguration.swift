struct FileNameConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted()), " +
            "prefix_pattern: \(prefixPattern), " +
            "suffix_pattern: \(suffixPattern), " +
            "nested_type_separator: \(nestedTypeSeparator)"
    }

    private(set) var severity: SeverityConfiguration
    private(set) var excluded: Set<String>
    private(set) var prefixPattern: String
    private(set) var suffixPattern: String
    private(set) var nestedTypeSeparator: String

    init(severity: ViolationSeverity, excluded: [String] = [],
         prefixPattern: String = "", suffixPattern: String = "\\+.*", nestedTypeSeparator: String = ".") {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
        self.prefixPattern = prefixPattern
        self.suffixPattern = suffixPattern
        self.nestedTypeSeparator = nestedTypeSeparator
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
