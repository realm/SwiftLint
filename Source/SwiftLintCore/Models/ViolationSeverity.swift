/// The magnitude of a `StyleViolation`.
@AcceptableByConfigurationElement
public enum ViolationSeverity: String, Comparable, Codable, Sendable, InlinableOptionType {
    /// Non-fatal. If using SwiftLint as an Xcode build phase, Xcode will mark the build as having succeeded.
    case warning
    /// Fatal. If using SwiftLint as an Xcode build phase, Xcode will mark the build as having failed.
    case error

    // MARK: Comparable

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs == .warning && rhs == .error
    }
}
