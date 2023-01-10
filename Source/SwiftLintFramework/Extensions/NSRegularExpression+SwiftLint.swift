import Foundation
import SourceKittenFramework

private var regexCache = [RegexCacheKey: NSRegularExpression]()
private let regexCacheLock = NSLock()

private struct RegexCacheKey: Hashable {
    let pattern: String
    let options: NSRegularExpression.Options

    func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
        hasher.combine(options.rawValue)
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

    internal func matches(in stringView: StringView,
                          options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        return matches(in: stringView.string, options: options, range: stringView.range)
    }

    internal func matches(in stringView: StringView,
                          options: NSRegularExpression.MatchingOptions = [],
                          range: NSRange) -> [NSTextCheckingResult] {
        return matches(in: stringView.string, options: options, range: range)
    }

    internal func matches(in file: SwiftLintFile,
                          options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        return matches(in: file.stringView.string, options: options, range: file.stringView.range)
    }
}

/// `NSRegularExpression` wrapper that considers two instances of itself as equal if the regex pattern and the
/// regex properties match. This is different from `NSRegularExpression`s where two instances are only equal
/// if they point to the exact same object.
final class ComparableRegex: NSObject {
    private let regex: NSRegularExpression
    private let comparisonKey: RegexCacheKey

    /// Creates a `ComparableRegex` instance.
    ///
    /// - parameter pattern: The regular expression as a string.
    /// - parameter options: Regular expression properties.
    init?(pattern: String, options: NSRegularExpression.Options? = nil) {
        guard let regex = try? NSRegularExpression.cached(pattern: pattern, options: options) else {
            return nil
        }
        self.regex = regex
        self.comparisonKey = RegexCacheKey(pattern: pattern, options: regex.options)
    }

    var pattern: String {
        regex.pattern
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Self {
            return comparisonKey == object.comparisonKey
        }
        return false
    }

    override var hash: Int {
        comparisonKey.hashValue
    }

    func matches(string: String) -> Bool {
        !regex.matches(in: string, options: [], range: NSRange(string.startIndex..., in: string)).isEmpty
    }
}
