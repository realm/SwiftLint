public struct FunctionBodyLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "warning: \(severityConfiguration.warning)" +
        (severityConfiguration.error.map({ "error: \($0)" }) ?? "") +
        "excluded: \(excluded.sorted())"
    }

    var severityConfiguration: SeverityLevelsConfiguration
    var excluded: Set<String>

    public init(warning: Int, error: Int?, excluded: [String] = []) {
        self.severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        self.excluded = Set(excluded)
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let warningConfiguration = configurationDict["warning"] as? Int {
            severityConfiguration.warning = warningConfiguration
        }

        if let errorConfiguration = configurationDict["error"] as? Int {
            severityConfiguration.error = errorConfiguration
        }

        if let excludedConfiguration = configurationDict["excluded"] as? String {
            self.excluded = Set([excludedConfiguration])
        }

        if let excludedConfiguration = configurationDict["excluded"] as? [String] {
            self.excluded = Set(excludedConfiguration)
        }
    }
}
