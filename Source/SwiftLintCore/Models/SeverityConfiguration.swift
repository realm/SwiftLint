/// A rule configuration that allows specifying the desired severity level for violations.
public struct SeverityConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, InlinableOptionType {
    /// Configuration with a warning severity.
    public static var error: Self { Self(.error) }
    /// Configuration with an error severity.
    public static var warning: Self { Self(.warning) }

    @ConfigurationElement(key: "severity")
    private (set) var violationSeverity = ViolationSeverity.warning

    public var severity: SeverityConfiguration {
        self
    }

    /// Create a `SeverityConfiguration` with the specified severity.
    ///
    /// - parameter severity: The severity that should be used when emitting violations.
    public init(_ violationSeverity: ViolationSeverity) {
        self.violationSeverity = violationSeverity
    }

    public mutating func apply(configuration: Any) throws {
        let configString = configuration as? String
        let configDict = configuration as? [String: Any]
        if let severityString: String = configString ?? configDict?[$violationSeverity.key] as? String {
            if let violationSeverity = ViolationSeverity(rawValue: severityString.lowercased()) {
                self.violationSeverity = violationSeverity
            } else {
                throw Issue.invalidConfiguration(ruleID: Parent.identifier)
            }
        } else {
            throw Issue.nothingApplied(ruleID: Parent.identifier)
        }
    }
}
