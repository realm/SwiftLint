struct BaselineViolation: Equatable {
    let ruleIdentifier: String
    let location: String
    let reason: String

    static func == (lhs: BaselineViolation, rhs: BaselineViolation) -> Bool {
        return lhs.ruleIdentifier == rhs.ruleIdentifier &&
                lhs.location == rhs.location &&
                lhs.reason == rhs.reason
    }
}
