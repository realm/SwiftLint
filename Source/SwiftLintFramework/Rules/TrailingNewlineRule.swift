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
        let string = file.contents
        let start = advance(string.endIndex, -2, string.startIndex)
        let range = Range(start: start, end: string.endIndex)
        let substring = string[range].utf16
        let newLineSet = NSCharacterSet.newlineCharacterSet()
        let slices = substring.split(allowEmptySlices: true) { !newLineSet.characterIsMember($0) }

        if let slice = slices.last where slice.count != 1 {
            return [StyleViolation(type: .TrailingNewline,
                location: Location(file: file.path, line: file.contents.lines().count + 1),
                severity: .Medium,
                reason: "File should have a single trailing newline")]
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
