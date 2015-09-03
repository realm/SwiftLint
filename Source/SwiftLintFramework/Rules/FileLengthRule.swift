//
//  FileLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FileLengthRule: ParameterizedRule {
    public init() {}

    public let identifier = "file_length"

    public let parameters = [
        RuleParameter(severity: .Warning, value: 400),
        RuleParameter(severity: .Error, value: 1000)
    ]

    public func validateFile(file: File) -> [StyleViolation] {
        let lineCount = file.lines.count
        for parameter in parameters.reverse() {
            if lineCount > parameter.value {
                return [StyleViolation(type: .Length,
                    location: Location(file: file.path, line: lineCount),
                    severity: parameter.severity,
                    reason: "File should contain 400 lines or less: currently contains " +
                    "\(lineCount)")]
            }
        }
        return []
    }

    public let example = RuleExample(
        ruleName: "File Line Length Rule",
        ruleDescription: "Files should be less than 400 lines.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
