struct FileNameConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(severity) \(severityConfiguration.consoleDescription), " +
            "excluded: \(excluded.sorted()), " +
            "prefix_pattern: \(prefixPattern), " +
            "suffix_pattern: \(suffixPattern), " +
            "nested_type_separator: \(nestedTypeSeparator)"
    }

    private(set) var severityConfiguration = SeverityConfiguration.warning
    private(set) var excluded = Set<String>(["main.swift", "LinuxMain.swift"])
    private(set) var prefixPattern = ""
    private(set) var suffixPattern = "\\+.*"
    private(set) var nestedTypeSeparator = "."

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
