internal struct HashableRuleWrapper: Hashable {
    let rule: Rule

    static func == (lhs: HashableRuleWrapper, rhs: HashableRuleWrapper) -> Bool {
        // Only use identifier for equality check (not taking config into account)
        return type(of: lhs.rule).description.identifier == type(of: rhs.rule).description.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type(of: rule).description.identifier)
    }
}
