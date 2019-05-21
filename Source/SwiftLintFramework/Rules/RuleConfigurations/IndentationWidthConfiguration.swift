public struct IndentationWidthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription), " + "indentation_width: \(indentationWidth)"
    }

    private(set) public var severityConfiguration: SeverityConfiguration
    private(set) public var indentationWidth: Int

    public init(
        severity: ViolationSeverity,
        indentationWidth: Int
    ) {
        self.severityConfiguration = SeverityConfiguration(severity)
        self.indentationWidth = indentationWidth
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let config = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: config)
        }

        if let indentationWidth = configurationDict["indentation_width"] as? Int, indentationWidth >= 1 {
            self.indentationWidth = indentationWidth
        }
    }
}
