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
            repeatElement("/", count: 100).joined() + "\n"
        ],
        triggeringExamples: [
            repeatElement("/", count: 101).joined() + "\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let minValue = configuration.params.map({$0.value}).min(by: <)
        return file.lines.flatMap { line in
            // `line.content.characters.count` <= `line.range.length` is true.
            // So, `check line.range.length` is larger than minimum parameter value.
            // for avoiding using heavy `line.content.characters.count`.
            if line.range.length < minValue! {
                return nil
            }
            let length = line.content.characters.count
            for param in configuration.params where length > param.value {
                return StyleViolation(ruleDescription: type(of: self).description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(configuration.warning) characters or less: " +
                        "currently \(length) characters")
            }
            return nil
        }
    }
}
