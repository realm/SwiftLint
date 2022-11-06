/// A value describing a SwiftLint violation that was corrected.
public struct Correction: Equatable {
    /// The description of the rule for which this correction was applied.
    public let ruleDescription: RuleDescription
    /// The location of the original violation that was corrected.
    public let location: Location

    /// Memberwise initializer.
    ///
    /// - parameter ruleDescription: The description of the rule for which this correction was applied.
    /// - parameter location:        The location of the original violation that was corrected.
    public init(ruleDescription: RuleDescription, location: Location) {
        self.ruleDescription = ruleDescription
        self.location = location
    }

    /// The console-printable description for this correction.
    public var consoleDescription: String {
        return "\(location) Corrected \(ruleDescription.name)"
    }
}
