//
//  ReturningWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 2/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ReturnArrowWhitespaceRule: ConfigProviderRule {

    public var config = SeverityConfig(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line.",
        nonTriggeringExamples: [
            Trigger("func abc() -> Int {}\n"),
            Trigger("func abc() -> [Int] {}\n"),
            Trigger("func abc() -> (Int, Int) {}\n"),
            Trigger("var abc = {(param: Int) -> Void in }\n"),
            Trigger("func abc() ->\n    Int {}\n"),
            Trigger("func abc()\n    -> Int {}\n")
        ],
        triggeringExamples: [
            Trigger("func abc(↓)->Int {}\n"),
            Trigger("func abc(↓)->[Int] {}\n"),
            Trigger("func abc(↓)->(Int, Int) {}\n"),
            Trigger("func abc(↓)-> Int {}\n"),
            Trigger("func abc(↓) ->Int {}\n"),
            Trigger("func abc(↓)  ->  Int {}\n"),
            Trigger("var abc = {(param: Int↓) ->Bool in }\n"),
            Trigger("var abc = {(param: Int↓)->Bool in }\n")
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
                severity: config.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }
}
