public struct DirectoryNameNoSpaceConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted()), " +
            "parent_directory: \(parentDirectory)"
    }

    public private(set) var severity: SeverityConfiguration
    public private(set) var excluded: Set<String>
    public private(set) var parentDirectory: String

    public init(severity: ViolationSeverity, excluded: [String] = [],
                parentDirectory: String = "SwiftLint") {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
        self.parentDirectory = parentDirectory
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
        if let parentDirectory = configurationDict["parent_directory"] as? String {
            self.parentDirectory = parentDirectory
        }
    }
}
