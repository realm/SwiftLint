/// A configuration value for a rule to allow users to modify its behavior.
public protocol RuleConfiguration {
    /// A human-readable description for this configuration and its applied values.
    var consoleDescription: String { get }

    /// Apply an untyped configuration to the current value.
    ///
    /// - throws: Throws if the configuration is not in the expected format.
    mutating func apply(configuration: Any) throws

    /// Whether the specified configuration is equivalent to the current value.
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool
}

public extension RuleConfiguration where Self: Equatable {
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        return self == ruleConfiguration as? Self
    }
}
