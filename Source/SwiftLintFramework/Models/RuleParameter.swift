public struct RuleParameter<T: Equatable>: Equatable {
    public let severity: ViolationSeverity
    public let value: T

    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}

// MARK: - Equatable

public func ==<T> (lhs: RuleParameter<T>, rhs: RuleParameter<T>) -> Bool {
    return lhs.value == rhs.value && lhs.severity == rhs.severity
}
