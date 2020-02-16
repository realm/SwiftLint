public struct UnusedImportConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return [
            "severity: \(severity.consoleDescription)",
            "require_explicit_imports: \(requireExplicitImports)"
        ].joined(separator: ", ")
    }

    public private(set) var severity: SeverityConfiguration
    public private(set) var requireExplicitImports: Bool

    public init(severity: ViolationSeverity, requireExplicitImports: Bool) {
        self.severity = SeverityConfiguration(severity)
        self.requireExplicitImports = requireExplicitImports
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }
        if let requireExplicitImports = configurationDict["require_explicit_imports"] as? Bool {
            self.requireExplicitImports = requireExplicitImports
        }
    }
}
