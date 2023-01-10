import Foundation

/// Represents regex from `exclude` option in `NameConfiguration`.
/// Using NSRegularExpression causes failure on equality check between two `NameConfiguration`s.
/// This class compares pattern only when checking its equality
public final class ExcludedRegexExpression: NSObject {
    /// NSRegularExpression built from given pattern
    public let regex: NSRegularExpression

    /// Creates an `ExcludedRegexExpression` with a pattern.
    ///
    /// - parameter pattern:   The pattern string to build regex
    init?(pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern)  else { return nil }
        self.regex = regex
    }

    // MARK: - Equality Check

    /// Compares regex pattern to check equality
    override public func isEqual(_ object: Any?) -> Bool {
        if let object = object as? ExcludedRegexExpression {
            return regex.pattern == object.regex.pattern
        } else {
            return false
        }
    }

    /// Uses regex pattern as hash
    override public var hash: Int {
        return regex.pattern.hashValue
    }
}
