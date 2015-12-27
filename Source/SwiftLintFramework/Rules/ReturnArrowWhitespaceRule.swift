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
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        // just horizontal spacing so that "func abc()->\n" can pass validation
        let space = "[ \\f\\r\\t]"
        let spaceRegex = "(\(space){0}|\(space){2,})"

        // ex: `func abc()-> Int {` & `func abc() ->Int {`
        let pattern = "\\)(\(spaceRegex)\\->\\s*|\\s\\->\(spaceRegex))\\S+"
        return file.matchPattern(pattern, withSyntaxKinds: [.Typeidentifier]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }
}
