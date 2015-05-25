//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LineLengthRule: ParameterizedRule {
    public init() {}

    public let identifier = "line_length"

    public let parameters = [
        RuleParameter(severity: .VeryLow, value: 100),
        RuleParameter(severity: .Low, value: 120),
        RuleParameter(severity: .Medium, value: 150),
        RuleParameter(severity: .High, value: 200),
        RuleParameter(severity: .VeryHigh, value: 250)
    ]

    public func validateFile(file: File) -> [StyleViolation] {
        return compact(file.contents.lines().map { line in
            for parameter in reverse(self.parameters) {
                if count(line.content) > parameter.value {
                    return StyleViolation(type: .Length,
                        location: Location(file: file.path, line: line.index),
                        severity: parameter.severity,
                        reason: "Line should be 100 characters or less: currently " +
                        "\(count(line.content)) characters")
                }
            }
            return nil
        })
    }

    public let example = RuleExample(
        ruleName: "Line Length Rule",
        ruleDescription: "Lines should be less than 100 characters.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
