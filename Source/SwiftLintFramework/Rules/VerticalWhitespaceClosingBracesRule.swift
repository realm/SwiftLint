import Foundation
import SourceKittenFramework

public struct VerticalWhitespaceClosingBracesRule {
    public init() {}

    private static let invalidToValidExamples: [String: String] = [
        "print(\"x is 5\")\n↓\n}": "print(\"x is 5\")\n}",
        "print(\"x is 5\")\n↓\n\n}": "print(\"x is 5\")\n}",
        "print(\"x is 5\")\n    ↓\n}": "print(\"x is 5\")\n}"
    ]
}

extension VerticalWhitespaceClosingBracesRule: Rule {
    public var configurationDescription: String { return "N/A" }

    public init(configuration: Any) throws {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace_opening_braces",
        name: "Vertical Whitespace after Opening Braces",
        description: "Don't include vertical whitespace (empty line) after opening braces.",
        kind: .style,
        nonTriggeringExamples: Array(invalidToValidExamples.values),
        triggeringExamples: invalidToValidExamples.keys.map({ $0.replacingOccurrences(of: "↓", with: "") }),
        corrections: invalidToValidExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        // TODO: not yet implemented
        return []
    }
}

extension VerticalWhitespaceClosingBracesRule: CorrectableRule {
    public func correct(file: File) -> [Correction] {
        // TODO: not yet implemented
        return []
    }
}
