/// A rule configuration that allows to disable (`off`) an option of a rule or specify its severity level in which
/// case it's active.
public struct ChildOptionSeverityConfiguration<Parent: Rule>: RuleConfiguration,
                                                              AcceptableByConfigurationElement,
                                                              Sendable {
    /// Configuration with a warning severity.
    public static var error: Self { Self(optionSeverity: .error) }
    /// Configuration with an error severity.
    public static var warning: Self { Self(optionSeverity: .warning) }
    /// Configuration disabling an option.
    public static var off: Self { Self(optionSeverity: .off) }

    enum ChildOptionSeverity: String {
        case warning, error, off
    }

    private var optionSeverity: ChildOptionSeverity

    /// The `ChildOptionSeverityConfiguration` mapped to a usually used `ViolationSeverity`. It's `nil` if the option
    /// is set to `off`.
    public var severity: ViolationSeverity? {
        ViolationSeverity(rawValue: optionSeverity.rawValue)
    }

    public mutating func apply(configuration: Any) throws {
        guard let configString = configuration as? String,
            let optionSeverity = ChildOptionSeverity(rawValue: configString.lowercased()) else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }
        self.optionSeverity = optionSeverity
    }

    public func asOption() -> OptionType { .symbol(optionSeverity.rawValue) }
}
