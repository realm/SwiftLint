/// A configuration value for a rule to allow users to modify its behavior.
public protocol RuleConfiguration: Equatable {
    /// The type of the rule that's using this configuration.
    associatedtype Parent: Rule

    /// A description for this configuration's parameters. It can be built using the annotated result builder.
    @RuleConfigurationDescriptionBuilder
    var parameterDescription: RuleConfigurationDescription? { get }

    /// Apply an untyped configuration to the current value.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - throws: Throws if the configuration is not in the expected format.
    mutating func apply(configuration: Any) throws
}

/// A configuration for a rule that allows to configure at least the severity.
public protocol SeverityBasedRuleConfiguration: RuleConfiguration {
    /// The configuration of a rule's severity.
    var severity: SeverityConfiguration<Parent> { get }
}

public extension SeverityBasedRuleConfiguration {
    /// The severity of a rule.
    var violationSeverity: ViolationSeverity {
        severity.violationSeverity
    }
}

public extension RuleConfiguration {
    var parameterDescription: RuleConfigurationDescription? { nil }
}

public extension RuleConfiguration {
    /// All keys supported by this configuration.
    var supportedKeys: Set<String> {
        Set(RuleConfigurationDescription.from(configuration: self).allowedKeys())
    }
}
