//
//  FileLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FileLengthRule: ConfigurationProviderRule {
    public var configuration = FileLenghtRuleConfiguration(warning: 400, error: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_length",
        name: "File Line Length",
        description: "Files should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            repeatElement("print(\"swiftlint\")\n", count: 400).joined()
        ],
        triggeringExamples: [
            repeatElement("print(\"swiftlint\")\n", count: 401).joined(),
            (repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        func getLineCountWithoutComments() -> Int {
            let commentKinds = Set(SyntaxKind.commentKinds())
            let lineCount = file.syntaxKindsByLines.filter { kinds in
                return !kinds.filter { !commentKinds.contains($0) }.isEmpty
            }.count
            return lineCount
        }

        var lineCount = file.lines.count

        let hasViolation = configuration.severityConfiguration.params.contains {
            $0.value < lineCount
        }

        if hasViolation && configuration.ignoreCommentOnlyLines {
            lineCount = getLineCountWithoutComments()
        }

        for parameter in configuration.severityConfiguration.params where lineCount > parameter.value {
            let reason = "File should contain \(configuration.severityConfiguration.warning) lines or less: " +
                         "currently contains \(lineCount)"
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: parameter.severity,
                                   location: Location(file: file.path, line: lineCount),
                                   reason: reason)]
        }
        return []
    }
}
