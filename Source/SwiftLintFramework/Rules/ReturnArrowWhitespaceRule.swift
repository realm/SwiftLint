//
//  ReturningWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 2/6/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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
            "func abc() -> Int {}\n",
            "func abc() -> [Int] {}\n",
            "func abc() -> (Int, Int) {}\n",
            "var abc = {(param: Int) -> Void in }\n",
            "func abc() ->\n    Int {}\n",
            "func abc()\n    -> Int {}\n"
        ],
        triggeringExamples: [
            "func abc()↓->Int {}\n",
            "func abc()↓->[Int] {}\n",
            "func abc()↓->(Int, Int) {}\n",
            "func abc()↓-> Int {}\n",
            "func abc()↓ ->Int {}\n",
            "func abc()↓  ->  Int {}\n",
            "var abc = {(param: Int)↓ ->Bool in }\n",
            "var abc = {(param: Int)↓->Bool in }\n"
        ],
        corrections: [
            "func abc()↓->Int {}\n": "func abc() -> Int {}\n",
            "func abc()↓-> Int {}\n": "func abc() -> Int {}\n",
            "func abc()↓ ->Int {}\n": "func abc() -> Int {}\n",
            "func abc()↓  ->  Int {}\n": "func abc() -> Int {}\n",
            "func abc()↓\n  ->  Int {}\n": "func abc()\n  -> Int {}\n",
            "func abc()↓\n->  Int {}\n": "func abc()\n-> Int {}\n",
            "func abc()↓  ->\n  Int {}\n": "func abc() ->\n  Int {}\n",
            "func abc()↓  ->\nInt {}\n": "func abc() ->\nInt {}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file, skipParentheses: true).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violationsRanges = violationRanges(in: file, skipParentheses: false)
        let matches = file.ruleEnabled(violatingRanges: violationsRanges, for: self)
        if matches.isEmpty { return [] }
        let regularExpression = regex(pattern)
        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents

        let results = matches.reversed().flatMap { range in
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
        //just horizontal spacing so that "func abc()->\n" can pass validation
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

    private func violationRanges(in file: File, skipParentheses: Bool) -> [NSRange] {
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
