//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LineLengthRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityLevelsConfiguration(warning: 100, error: 200)

    public init() {}

    public static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters.",
        nonTriggeringExamples: [
            Repeat(count: 100, repeatedValue: "/").joinWithSeparator("") + "\n"
        ],
        triggeringExamples: [
            Repeat(count: 101, repeatedValue: "/").joinWithSeparator("") + "\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let minValue = configuration.params.map({$0.value}).minElement(<)
        return file.lines.flatMap { line in
            // `line.content.characters.count` <= `line.range.length` is true.
            // So, `check line.range.length` is larger than minimum parameter value.
            // for avoiding using heavy `line.content.characters.count`.
            if line.range.length < minValue {
                return nil
            }
            let length = line.content.characters.count
            for param in configuration.params where length > param.value {
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(configuration.warning) characters or less: " +
                    "currently \(length) characters")
            }
            return nil
        }
    }
}
