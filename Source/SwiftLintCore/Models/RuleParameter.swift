/// A configuration parameter for rules.
public struct RuleParameter<T: Equatable>: Equatable {
    /// The severity that should be assigned to the violation of this parameter's value is met.
    public let severity: ViolationSeverity
    /// The value to configure the rule.
    public let value: T

    /// Creates a `RuleParameter` by specifying its properties directly.
    ///
    /// - parameter severity: The severity that should be assigned to the violation of this parameter's value is met.
    /// - parameter value:    The value to configure the rule.
    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}
