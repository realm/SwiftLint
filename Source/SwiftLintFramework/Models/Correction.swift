public struct Correction: Equatable {
    public let ruleDescription: RuleDescription
    public let location: Location

    public var consoleDescription: String {
        return "\(location) Corrected \(ruleDescription.name)"
    }
}

// MARK: Equatable

public func == (lhs: Correction, rhs: Correction) -> Bool {
    return lhs.ruleDescription == rhs.ruleDescription &&
        lhs.location == rhs.location
}
