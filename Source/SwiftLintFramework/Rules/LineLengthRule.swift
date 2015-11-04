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

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Enforce maximum line length"
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.flatMap { line in
            for param in parameters.reverse() where line.content.characters.count > param.value {
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(parameters.first!.value) characters or less: " +
                    "currently \(line.content.characters.count) characters")
            }
            return nil
        }
    }
}
