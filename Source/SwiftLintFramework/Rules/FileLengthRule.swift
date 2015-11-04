//
//  FileLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FileLengthRule: ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 400),
            RuleParameter(severity: .Error, value: 1000)
        ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "file_length",
        name: "File Line Length",
        description: "Enforce maximum file length"
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let lineCount = file.lines.count
        for parameter in parameters.reverse() {
            if lineCount > parameter.value {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file.path, line: lineCount),
                    reason: "File should contain \(parameters.first!.value) lines or less: " +
                    "currently contains \(lineCount)")]
            }
        }
        return []
    }
}
