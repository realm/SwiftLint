/// A rule configuration that allows specifying the desired severity level for violations.
public struct SeverityConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    /// Configuration with a warning severity.
    public static var error: Self { Self(.error) }
    /// Configuration with an error severity.
    public static var warning: Self { Self(.warning) }

    public var parameterDescription: RuleConfigurationDescription {
         "severity" => .symbol(severity.rawValue)
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
            throw Issue.unknownConfiguration(ruleID: Parent.description.identifier)
        }
        self.severity = severity
    }
}
