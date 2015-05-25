//
//  TrailingNewlineRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingNewlineRule: Rule {
    public init() {}

    public let identifier = "trailing_newline"

    public func validateFile(file: File) -> [StyleViolation] {
        let countOfTrailingNewlines = file.contents.countOfTailingCharactersInSet(
            NSCharacterSet.newlineCharacterSet()
        )
        if countOfTrailingNewlines != 1 {
            return [StyleViolation(type: .TrailingNewline,
                location: Location(file: file.path),
                severity: .Medium,
                reason: "File should have a single trailing newline: " +
                "currently has \(countOfTrailingNewlines)")]
        }
        return []
    }

    public let example = RuleExample(
        ruleName: "Trailing newline rule",
        ruleDescription: "Files should have a single trailing newline.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
