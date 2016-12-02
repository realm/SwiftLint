//
//  FileLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FileLengthRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityLevelsConfiguration(warning: 400, error: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_length",
        name: "File Line Length",
        description: "Files should not span too many lines.",
        nonTriggeringExamples: [
            repeatElement("//\n", count: 400).joined(separator: "")
        ],
        triggeringExamples: [
            repeatElement("//\n", count: 401).joined(separator: "")
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let lineCount = file.lines.count
        for parameter in configuration.params where lineCount > parameter.value {
            return [StyleViolation(ruleDescription: type(of: self).description,
                severity: parameter.severity,
                location: Location(file: file.path, line: lineCount),
                reason: "File should contain \(configuration.warning) lines or less: " +
                        "currently contains \(lineCount)")]
        }
        return []
    }
}
