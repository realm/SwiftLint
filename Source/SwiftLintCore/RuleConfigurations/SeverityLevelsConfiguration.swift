/// A rule configuration that allows specifying thresholds for `warning` and `error` severities.
public struct SeverityLevelsConfiguration<Parent: Rule>: RuleConfiguration, InlinableOptionType, Sendable {
    /// The threshold for a violation to be a warning.
    @ConfigurationElement(key: "warning")
    public var warning = 12
    /// The threshold for a violation to be an error.
    @ConfigurationElement(key: "error")
    public var error: Int?

    /// Create a `SeverityLevelsConfiguration` based on the specified `warning` and `error` thresholds.
    ///
    /// - parameter warning: The threshold for a violation to be a warning.
    /// - parameter error:   The threshold for a violation to be an error.
    public init(warning: Int, error: Int? = nil) {
        self.warning = warning
        self.error = error
    }

    /// The rule parameters that define the thresholds that should map to each severity.
    public var params: [RuleParameter<Int>] {
        if let error {
            return [
                RuleParameter(severity: .error, value: error),
                RuleParameter(severity: .warning, value: warning),
            ]
        }
        return [RuleParameter(severity: .warning, value: warning)]
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration), configurationArray.isNotEmpty {
            warning = configurationArray[0]
            error = (configurationArray.count > 1) ? configurationArray[1] : nil
        } else if let configDict = configuration as? [String: Any?] {
            if let warningValue = configDict[$warning.key] {
                if let warning = warningValue as? Int {
                    self.warning = warning
                } else {
                    throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                }
            }
            if let errorValue = configDict[$error.key] {
                if errorValue == nil {
                    self.error = nil
                } else if let error = errorValue as? Int {
                    self.error = error
                } else {
                    throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                }
            } else {
                self.error = nil
            }
        } else {
            throw Issue.nothingApplied(ruleID: Parent.identifier)
        }
    }
}
