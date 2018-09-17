public enum ViolationSeverity: String, Comparable {
    case warning
    case error

    // MARK: Comparable

    public static func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
        return lhs == .warning && rhs == .error
    }
}
