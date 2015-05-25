//
//  LeadingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LeadingWhitespaceRule: Rule {
    public init() {}

    public let identifier = "leading_whitespace"

    public func validateFile(file: File) -> [StyleViolation] {
        let countOfLeadingWhitespace = file.contents.countOfLeadingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        if countOfLeadingWhitespace != 0 {
            return [StyleViolation(type: .LeadingWhitespace,
                location: Location(file: file.path, line: 1),
                severity: .Medium,
                reason: "File shouldn't start with whitespace: " +
                "currently starts with \(countOfLeadingWhitespace) whitespace characters")]
        }
        return []
    }

    public let example = RuleExample(
        ruleName: "Leading Whitespace Rule",
        ruleDescription: "This rule checks that there's no leading whitespace in your file.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "\n", " //\n" ],
        showExamples: false
    )
}
