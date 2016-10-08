//
//  ReturningWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 2/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ReturnArrowWhitespaceRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line.",
        nonTriggeringExamples: [
            "func abc() -> Int {}\n",
            "func abc() -> [Int] {}\n",
            "func abc() -> (Int, Int) {}\n",
            "var abc = {(param: Int) -> Void in }\n",
            "func abc() ->\n    Int {}\n",
            "func abc()\n    -> Int {}\n"
        ],
        triggeringExamples: [
            "func abc(↓)->Int {}\n",
            "func abc(↓)->[Int] {}\n",
            "func abc(↓)->(Int, Int) {}\n",
            "func abc(↓)-> Int {}\n",
            "func abc(↓) ->Int {}\n",
            "func abc(↓)  ->  Int {}\n",
            "var abc = {(param: Int↓) ->Bool in }\n",
            "var abc = {(param: Int↓)->Bool in }\n"
        ],
        corrections: [
            "func abc()->Int {}\n": "func abc() -> Int {}\n",
            "func abc()-> Int {}\n": "func abc() -> Int {}\n",
            "func abc() ->Int {}\n": "func abc() -> Int {}\n",
            "func abc()  ->  Int {}\n": "func abc() -> Int {}\n",
            "func abc()\n  ->  Int {}\n": "func abc()\n  -> Int {}\n",
            "func abc()\n->  Int {}\n": "func abc()\n-> Int {}\n",
            "func abc()  ->\n  Int {}\n": "func abc() ->\n  Int {}\n",
            "func abc()  ->\nInt {}\n": "func abc() ->\nInt {}\n",
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        return violationRangesInFile(file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let matches = violationRangesInFile(file)
        guard !matches.isEmpty else { return [] }

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
                if let range = contents.nsrangeToIndexRange(result.rangeAt(index)) {
                    contents.replaceSubrange(range, with: string)
                    break
                }
            }

            let location = Location(file: file, characterOffset: result.range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    // MARK: - Private

    fileprivate let pattern: String = {
        //just horizontal spacing so that "func abc()->\n" can pass validation
        let space = "[ \\f\\r\\t]"

        // Either 0 space characters or 2+
        let incorrectSpace = "(\(space){0}|\(space){2,})"

        // The possible combinations of whitespace around the arrow
        let patterns = [
            "(\(incorrectSpace)\\->\(space)*)",
            "(\(space)\\->\(incorrectSpace))",
            "\\n\(space)*\\->\(incorrectSpace)",
            "\(incorrectSpace)\\->\\n\(space)*",
        ]

        // ex: `func abc()-> Int {` & `func abc() ->Int {`
        return "\\)(\(patterns.joined(separator: "|")))\\S+"

    }()

    fileprivate func violationRangesInFile(_ file: File) -> [NSRange] {
        return file.matchPattern(pattern, withSyntaxKinds: [.Typeidentifier])
    }
}
