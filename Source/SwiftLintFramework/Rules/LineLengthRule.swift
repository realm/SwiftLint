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
    public static let name = "Line Length Rule"

    public let parameters = [
        RuleParameter(severity: .Warning, value: 100),
        RuleParameter(severity: .Error, value: 200)
    ]

    public func validateFile(file: File) -> [StyleViolation] {
        return file.contents.lines().flatMap { line in
            for parameter in parameters.reverse() {
                if line.content.characters.count > parameter.value {
                    return StyleViolation(rule: self,
                        location: Location(file: file.path, line: line.index),
                        severity: parameter.severity,
                        reason: "Line should be 100 characters or less: currently " +
                        "\(line.content.characters.count) characters")
                }
            }
            return nil
        }
    }

    public let example = RuleExample(
        ruleName: name,
        ruleDescription: "Lines should be less than 100 characters.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
