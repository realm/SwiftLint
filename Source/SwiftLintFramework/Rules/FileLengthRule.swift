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
    public static let name = "File Line Length Rule"

    public let parameters = [
        RuleParameter(severity: .Warning, value: 400),
        RuleParameter(severity: .Error, value: 1000)
    ]

    public func validateFile(file: File) -> [StyleViolation] {
        let lines = file.contents.lines()
        for parameter in parameters.reverse() {
            if lines.count > parameter.value {
                return [StyleViolation(rule: self,
                    location: Location(file: file.path, line: lines.count),
                    severity: parameter.severity,
                    reason: "File should contain 400 lines or less: currently contains " +
                    "\(lines.count)")]
            }
        }
        return []
    }

    public let example = RuleExample(
        ruleName: name,
        ruleDescription: "Files should be less than 400 lines.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
