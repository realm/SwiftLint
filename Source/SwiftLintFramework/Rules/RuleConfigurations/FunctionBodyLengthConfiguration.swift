public struct FunctionBodyLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "warning: \(severityConfiguration.warning)" +
        (severityConfiguration.error.map({ "error: \($0)" }) ?? "") +
        "excludedByName: \(excludedByName.sorted())" +
        "excludedBySignature: \(excludedBySignature.sorted())"
    }

    var severityConfiguration: SeverityLevelsConfiguration
    var excludedByName: Set<String>
    var excludedBySignature: Set<String>

    public init(warning: Int, error: Int?, excludedByName: [String] = [], excludedBySignature: [String] = []) {
        self.severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        self.excludedByName = Set(excludedByName)
        self.excludedBySignature = Set(excludedBySignature)
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

        if let excludedByNameConfiguration = configurationDict["excludedByName"] as? String {
            self.excludedByName = Set([excludedByNameConfiguration])
        }

        if let excludedByNameConfiguration = configurationDict["excludedByName"] as? [String] {
            self.excludedByName = Set(excludedByNameConfiguration)
        }

        if let excludedBySignatureConfiguration = configurationDict["excludedBySignature"] as? String {
            self.excludedBySignature = Set([excludedBySignatureConfiguration])
        }

        if let excludedBySignatureConfiguration = configurationDict["excludedBySignature"] as? [String] {
            self.excludedBySignature = Set(excludedBySignatureConfiguration)
        }
    }
}
