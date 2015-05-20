//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingWhitespaceRule: Rule, RuleExample {
    public init() { }

    let identifier = "trailing_whitespace"

    func validateFile(file: File) -> [StyleViolation] {
        return file.contents.lines().map { line in
            (
                index: line.index,
                trailingWhitespaceCount: line.content.countOfTailingCharactersInSet(
                    NSCharacterSet.whitespaceCharacterSet()
                )
            )
        }.filter {
            $0.trailingWhitespaceCount > 0
        }.map {
            StyleViolation(type: .TrailingWhitespace,
                location: Location(file: file.path, line: $0.index),
                severity: .Medium,
                reason: "Line #\($0.index) should have no trailing whitespace: " +
                "current has \($0.trailingWhitespaceCount) trailing whitespace characters")
        }
    }

    public var ruleName = "Trailing Whitespace Rule"

    public var ruleDescription = "This rule checks whether you don't have any trailing whitespace."

    public var correctExamples = [
        "//\n"
    ]

    public var failingExamples = [
        "// \n"
    ]

    public var showExamples = false
}
