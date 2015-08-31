//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingWhitespaceRule: Rule {
    public init() {}

    public let identifier = "trailing_whitespace"
    public static let name = "Trailing Whitespace Rule"

    public func validateFile(file: File) -> [StyleViolation] {
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
            StyleViolation(rule: self,
                location: Location(file: file.path, line: $0.index),
                severity: .Warning,
                reason: "Line #\($0.index) should have no trailing whitespace: " +
                "current has \($0.trailingWhitespaceCount) trailing whitespace characters")
        }
    }

    public let example = RuleExample(
        ruleName: name,
        ruleDescription: "This rule checks whether you don't have any trailing whitespace.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "// \n" ],
        showExamples: false
    )
}
