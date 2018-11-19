public struct Correction: Equatable {
    public let ruleDescription: RuleDescription
    public let location: Location

    public var consoleDescription: String {
        return "\(location) Corrected \(ruleDescription.name)"
    }
}
