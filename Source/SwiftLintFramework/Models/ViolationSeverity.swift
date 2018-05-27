public enum ViolationSeverity: String, Comparable {
    case warning
    case error
}

// MARK: Comparable

public func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs == .warning && rhs == .error
}
