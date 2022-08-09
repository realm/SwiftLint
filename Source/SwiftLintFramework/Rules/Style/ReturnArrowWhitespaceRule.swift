import Foundation
import SourceKittenFramework

public struct ReturnArrowWhitespaceRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc() -> Int {}\n"),
            Example("func abc() -> [Int] {}\n"),
            Example("func abc() -> (Int, Int) {}\n"),
            Example("var abc = {(param: Int) -> Void in }\n"),
            Example("func abc() ->\n    Int {}\n"),
            Example("func abc()\n    -> Int {}\n"),
            Example("typealias SuccessBlock = ((Data) -> Void)")
        ],
        triggeringExamples: [
            Example("func abc()↓->Int {}\n"),
            Example("func abc()↓->[Int] {}\n"),
            Example("func abc()↓->(Int, Int) {}\n"),
            Example("func abc()↓-> Int {}\n"),
            Example("func abc()↓ ->Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"),
            Example("var abc = {(param: Int)↓ ->Bool in }\n"),
            Example("var abc = {(param: Int)↓->Bool in }\n"),
            Example("typealias SuccessBlock = ((Data)↓->Void)")
        ],
        corrections: [
            Example("func abc()↓->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓-> Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓ ->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓\n  ->  Int {}\n"): Example("func abc()\n  -> Int {}\n"),
            Example("func abc()↓\n->  Int {}\n"): Example("func abc()\n-> Int {}\n"),
            Example("func abc()↓  ->\n  Int {}\n"): Example("func abc() ->\n  Int {}\n"),
            Example("func abc()↓  ->\nInt {}\n"): Example("func abc() ->\nInt {}\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file, skipParentheses: true).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violationsRanges = violationRanges(in: file, skipParentheses: false)
        let matches = file.ruleEnabled(violatingRanges: violationsRanges, for: self)
        if matches.isEmpty { return [] }
        let regularExpression = regex(pattern)
        let description = Self.description
        var corrections = [Correction]()
        var contents = file.contents

        let results = matches.reversed().compactMap { range in
            return regularExpression.firstMatch(in: contents, options: [], range: range)
        }

        let replacementsByIndex = [2: " -> ", 4: " -> ", 6: " ", 7: " "]

        for result in results {
            guard result.numberOfRanges > (replacementsByIndex.keys.max() ?? 0) else { break }

            for (index, string) in replacementsByIndex {
                if let range = contents.nsrangeToIndexRange(result.range(at: index)) {
                    contents.replaceSubrange(range, with: string)
                    break
                }
            }

            // skip the parentheses when reporting correction
            let location = Location(file: file, characterOffset: result.range.location + 1)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    // MARK: - Private

    private let pattern: String = {
        // Just horizontal spacing so that "func abc()->\n" can pass validation
        let space = "[ \\f\\r\\t]"

        // Either 0 space characters or 2+
        let incorrectSpace = "(\(space){0}|\(space){2,})"

        // The possible combinations of whitespace around the arrow
        let patterns = [
            "(\(incorrectSpace)\\->\(space)*)",
            "(\(space)\\->\(incorrectSpace))",
            "\\n\(space)*\\->\(incorrectSpace)",
            "\(incorrectSpace)\\->\\n\(space)*"
        ]

        // ex: `func abc()-> Int {` & `func abc() ->Int {`
        return "\\)(\(patterns.joined(separator: "|")))\\S+"
    }()

    private func violationRanges(in file: SwiftLintFile, skipParentheses: Bool) -> [NSRange] {
        let matches = file.match(pattern: pattern, with: [.typeidentifier])
        guard skipParentheses else {
            return matches
        }

        return matches.map {
            // skip first (
            NSRange(location: $0.location + 1, length: $0.length - 1)
        }
    }
}
