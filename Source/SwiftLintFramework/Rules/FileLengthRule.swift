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
        let lineCountWithComments = file.lines.count
        var lineCountWithoutComments: Int?

        func getLineCountwithoutComments() -> Int {
            if let lineCount = lineCountWithoutComments {
                return lineCount
            }
            let commentKinds = Set(SyntaxKind.commentKinds())
            let lineCount = file.syntaxKindsByLines.filter { kinds in
                return !kinds.filter { !commentKinds.contains($0) }.isEmpty
            }.count

            lineCountWithoutComments = lineCount
            return lineCount
        }

        for parameter in configuration.severityConfiguration.params where lineCountWithComments > parameter.value {
            if configuration.ignoreCommentOnlyLines {
                let lineCountWithoutComments = getLineCountwithoutComments()
                guard parameter.value < lineCountWithoutComments else { continue }
            }

            let reason = "File should contain \(configuration.severityConfiguration.warning) lines or less: " +
                         "currently contains \(lineCountWithoutComments ?? lineCountWithComments)"
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: parameter.severity,
                                   location: Location(file: file.path, line: lineCountWithoutComments),
                                   reason: reason)]
        }
        return []
    }
}
