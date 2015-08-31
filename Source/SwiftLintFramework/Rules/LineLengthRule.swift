//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LineLengthRule: ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 100),
            RuleParameter(severity: .Error, value: 200)
        ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let identifier = "line_length"

    public let parameters: [RuleParameter<Int>]

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.flatMap { line in
            for parameter in parameters.reverse() {
                if line.content.characters.count > parameter.value {
                    return StyleViolation(type: .Length,
                        location: Location(file: file.path, line: line.index),
                        severity: parameter.severity,
                        reason: "Line should be \(parameters.first!.value) characters or less: " +
                        "currently \(line.content.characters.count) characters")
                }
            }
            return nil
        }
    }

    public let example = RuleExample(
        ruleName: "Line Length Rule",
        ruleDescription: "Lines should be less than 100 characters.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
