import Foundation

public struct ExcludedRegexExpression: Equatable, Hashable {
    public let regex: NSRegularExpression

    init?(pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern)  else { return nil }
        self.regex = regex
    }
}

public extension ExcludedRegexExpression {
    static func == (lhs: ExcludedRegexExpression, rhs: ExcludedRegexExpression) -> Bool {
        return lhs.regex.pattern == rhs.regex.pattern
    }
}
