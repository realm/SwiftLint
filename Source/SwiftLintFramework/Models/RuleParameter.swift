public struct RuleParameter<T: Equatable>: Equatable {
    public let severity: ViolationSeverity
    public let value: T

    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}
