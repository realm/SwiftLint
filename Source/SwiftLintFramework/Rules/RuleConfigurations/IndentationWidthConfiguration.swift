public struct IndentationWidthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription), "
            + "indentation_width: \(indentationWidth), "
            + "include_comments: \(includeComments)"
    }

    public private(set) var severityConfiguration: SeverityConfiguration
    public private(set) var indentationWidth: Int
    public private(set) var includeComments: Bool
    public private(set) var includeCompilerDirectives: Bool

    public init(
        severity: ViolationSeverity,
        indentationWidth: Int,
        includeComments: Bool,
        includeCompilerDirectives: Bool
    ) {
        self.severityConfiguration = SeverityConfiguration(severity)
        self.indentationWidth = indentationWidth
        self.includeComments = includeComments
        self.includeCompilerDirectives = includeCompilerDirectives
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

        if let includeComments = configurationDict["include_comments"] as? Bool {
            self.includeComments = includeComments
        }

        if let includeCompilerDirectives = configurationDict["include_compiler_directives"] as? Bool {
            self.includeCompilerDirectives = includeCompilerDirectives
        }
    }
}
