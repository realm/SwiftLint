/// A value describing an instance of Swift source code that is considered invalid by a SwiftLint rule.
public struct StyleViolation: CustomStringConvertible, Equatable, Codable {
    /// The identifier of the rule that generated this violation.
    public let ruleIdentifier: String

    /// The description of the rule that generated this violation.
    public let ruleDescription: String

    /// The name of the rule that generated this violation.
    public let ruleName: String

    /// The severity of this violation.
    public var severity: ViolationSeverity

    /// The location of this violation.
    public var location: Location

    /// The justification for this violation.
    public let reason: String

    /// A printable description for this violation.
    public var description: String {
        return XcodeReporter.generateForSingleViolation(self)
    }

    /// Creates a `StyleViolation` by specifying its properties directly.
    ///
    /// - parameter ruleDescription: The description of the rule that generated this violation.
    /// - parameter severity:        The severity of this violation.
    /// - parameter location:        The location of this violation.
    /// - parameter reason:          The justification for this violation.
    public init(ruleDescription: RuleDescription,
                severity: ViolationSeverity = .warning,
                location: Location,
                reason: String? = nil) {
        self.ruleIdentifier = ruleDescription.identifier
        self.ruleDescription = ruleDescription.description
        self.ruleName = ruleDescription.name
        self.severity = severity
        self.location = location
        self.reason = reason ?? ruleDescription.description
    }
}
