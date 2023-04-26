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

public extension NSRegularExpression {
    static func cached(pattern: String, options: Options? = nil) throws -> NSRegularExpression {
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

    func matches(in stringView: StringView,
                 options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        return matches(in: stringView.string, options: options, range: stringView.range)
    }

    func matches(in stringView: StringView,
                 options: NSRegularExpression.MatchingOptions = [],
                 range: NSRange) -> [NSTextCheckingResult] {
        return matches(in: stringView.string, options: options, range: range)
    }

    func matches(in file: SwiftLintFile,
                 options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        return matches(in: file.stringView.string, options: options, range: file.stringView.range)
    }
}
