//
//  ReturningWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 2/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ReturnArrowWhitespaceRule: Rule {
    public init() {}

    public let identifier = "return_arrow_whitespace"

    public func validateFile(file: File) -> [StyleViolation] {
        // space doesn't include \n so that "func abc()->\n" can pass validation
        let space = "[ \\f\\r\\t\\v]"
        let spaceRegex = "(\(space){0}|\(space){2,})"

        // ex: func abc()-> Int {
        let pattern1 = file.matchPattern("\\)\(spaceRegex)\\->\\s*\\S+",
            withSyntaxKinds: [.Typeidentifier])

        // ex: func abc() ->Int {
        let pattern2 = file.matchPattern("\\)\\s\\->\(spaceRegex)\\S+",
            withSyntaxKinds: [.Typeidentifier])

        return (pattern1 + pattern2).map { match in
            return StyleViolation(type: .ReturnArrowWhitespace,
                location: Location(file: file, offset: match.location),
                severity: .Low,
                reason: "File should have 1 space before return arrow and return type")
        }
    }

    public let example = RuleExample(
        ruleName: "Returning Whitespace Rule",
        ruleDescription: "This rule checks whether you have 1 space before " +
        "return arrow and return type",
        nonTriggeringExamples: [
            "func abc() -> Int {}\n",
            "func abc() -> [Int] {}\n",
            "func abc() -> (Int, Int) {}\n",
            "var abc = {(param: Int) -> Void in }\n",
            "func abc() ->\n"
        ],
        triggeringExamples: [
            "func abc()->Int {}\n",
            "func abc()->[Int] {}\n",
            "func abc()->(Int, Int) {}\n",
            "func abc()-> Int {}\n",
            "func abc() ->Int {}\n",
            "func abc()  ->  Int {}\n",
            "var abc = {(param: Int) ->Bool in }\n",
            "var abc = {(param: Int)->Bool in }\n"
        ]
    )
}
