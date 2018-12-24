import Foundation

private var regexCache = [RegexCacheKey: NSRegularExpression]()
private let regexCacheLock = NSLock()

private struct RegexCacheKey: Hashable {
    // Disable unused private declaration rule here because even though we don't use these properties
    // directly, we rely on them for their hashable and equatable behavior.
    // swiftlint:disable unused_private_declaration
    let pattern: String
    let options: NSRegularExpression.Options
    // swiftlint:enable unused_private_declaration
}

extension NSRegularExpression.Options: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension NSRegularExpression {
    internal static func cached(pattern: String, options: Options? = nil) throws -> NSRegularExpression {
        let options = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
        let key = RegexCacheKey(pattern: pattern, options: options)
        regexCacheLock.lock()
        defer { regexCacheLock.unlock() }
        if let result = regexCache[key] {
            return result
        }

        let result = try NSRegularExpression(pattern: pattern, options: options)
        regexCache[key] = result
        return result
    }
}
