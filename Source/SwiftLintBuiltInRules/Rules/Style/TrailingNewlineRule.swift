import Foundation
import SourceKittenFramework

extension String {
    private func countOfTrailingCharacters(in characterSet: CharacterSet) -> Int {
        var count = 0
        for char in unicodeScalars.lazy.reversed() {
            if !characterSet.contains(char) {
                break
            }
            count += 1
        }
        return count
    }

    fileprivate func trailingNewlineCount() -> Int? {
        countOfTrailingCharacters(in: .newlines)
    }
}

struct TrailingNewlineRule: CorrectableRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "trailing_newline",
        name: "Trailing Newline",
        description: "Files should have a single trailing newline",
        kind: .style,
        nonTriggeringExamples: [
            Example("let a = 0\n")
        ],
        triggeringExamples: [
            Example("let a = 0"),
            Example("let a = 0\n\n"),
        ].skipWrappingInCommentTests().skipWrappingInStringTests(),
        corrections: [
            Example("let a = 0"): Example("let a = 0\n"),
            Example("let b = 0\n\n"): Example("let b = 0\n"),
            Example("let c = 0\n\n\n\n"): Example("let c = 0\n"),
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        if file.contents.trailingNewlineCount() == 1 {
            return []
        }
        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file.path, line: max(file.lines.count, 1))
            ),
        ]
    }

    func correct(file: SwiftLintFile) -> Int {
        guard let count = file.contents.trailingNewlineCount(), count != 1 else {
            return 0
        }
        guard let lastLineRange = file.lines.last?.range else {
            return 0
        }
        if file.ruleEnabled(violatingRanges: [lastLineRange], for: self).isEmpty {
            return 0
        }
        if count < 1 {
            file.append("\n")
        } else {
            let index = file.contents.index(file.contents.endIndex, offsetBy: 1 - count)
            file.write(file.contents[..<index])
        }
        return 1
    }
}
