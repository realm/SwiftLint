/// A value describing an instance of Swift source code that is considered invalid by a SwiftLint rule.
public struct StyleViolation: CustomStringConvertible, Equatable, Codable {
    /// The description of the rule that generated this violation.
    public let ruleDescription: RuleDescription

    /// The severity of this violation.
    public let severity: ViolationSeverity

    /// The location of this violation.
    public let location: Location

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
    public init(ruleDescription: RuleDescription, severity: ViolationSeverity = .warning,
                location: Location, reason: String? = nil) {
        self.ruleDescription = ruleDescription
        self.severity = severity
        self.location = location
        self.reason = reason ?? ruleDescription.description
    }
}
