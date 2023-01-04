import Foundation

public final class ExcludedRegexExpression: NSObject {
    public let regex: NSRegularExpression

    init?(pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern)  else { return nil }
        self.regex = regex
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? ExcludedRegexExpression {
            return regex.pattern == object.regex.pattern
        } else {
            return false
        }
    }

    public override var hash: Int {
        return regex.pattern.hashValue
    }
}
