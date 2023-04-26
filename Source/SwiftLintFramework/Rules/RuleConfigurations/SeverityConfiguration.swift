/// A rule configuration that allows specifying the desired severity level for violations.
public struct SeverityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public var consoleDescription: String {
        return severity.rawValue
    }

    var severity: ViolationSeverity

    public var severityConfiguration: SeverityConfiguration {
        self
    }

    /// Create a `SeverityConfiguration` with the specified severity.
    ///
    /// - parameter severity: The severity that should be used when emitting violations.
    public init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func apply(configuration: Any) throws {
        let configString = configuration as? String
        let configDict = configuration as? [String: Any]
        guard let severityString: String = configString ?? configDict?["severity"] as? String,
            let severity = ViolationSeverity(rawValue: severityString.lowercased()) else {
            throw ConfigurationError.unknownConfiguration
        }
        self.severity = severity
    }
}
