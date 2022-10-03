/// A configuration value for a rule to allow users to modify its behavior.
public protocol RuleConfiguration {
    /// A human-readable description for this configuration and its applied values.
    var consoleDescription: String { get }

    /// Apply an untyped configuration to the current value.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - throws: Throws if the configuration is not in the expected format.
    mutating func apply(configuration: Any) throws

    /// Whether the specified configuration is equivalent to the current value.
    ///
    /// - parameter ruleConfiguration: The rule configuration to compare against.
    ///
    /// - returns: Whether the specified configuration is equivalent to the current value.
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool
}

/// A configuration for a rule that allows to configure at least the severity.
public protocol SeverityBasedRuleConfiguration: RuleConfiguration {
    /// The configuration of a rule's severity.
    var severityConfiguration: SeverityConfiguration { get }
}

public extension SeverityBasedRuleConfiguration {
    /// The severity of a rule.
    var severity: ViolationSeverity {
        severityConfiguration.severity
    }
}

public extension RuleConfiguration where Self: Equatable {
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        return self == ruleConfiguration as? Self
    }
}
