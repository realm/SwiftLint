//
//  IndentationRule.swift
//  SwiftLint
//
//  Created by Lois Di Qual on 11/9/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct IndentationRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityLevelsConfiguration(warning: 400, error: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "indentation",
        name: "Indentation",
        description: "Source code should have consistent indentation. " +
            "Accepted indentations are tab characters or 4 spaces.",
        nonTriggeringExamples: [
            "\t",
            "    ",
            "\tfunc",
            "\t\tfunc",
            "\t\t\tfunc",
            "    func",
            "        func",
            "            func"
        ],
        triggeringExamples: [
            "\t    func",
            "    \tfunc",
            "    \t    func",
            "  func",
            "      func",
            "  \t  func",
            " func",
            " \t func"
        ]
    )

    private static let regex = try? NSRegularExpression(pattern: "(\\s*)\\S*", options: [])

    public func validateFile(file: File) -> [StyleViolation] {
        guard let regex = IndentationRule.regex else { return [] }

        var violations: [StyleViolation] = []
        for line in file.lines {
            let range = NSRange(location: 0, length: line.content.characters.count)
            let matches = regex.matchesInString(line.content, options: [], range: range)
            guard !matches.isEmpty else {
                continue
            }
            let linePrefix = (line.content as NSString)
                .substringWithRange(matches[0].rangeAtIndex(1))
            let spaceCount = linePrefix.componentsSeparatedByString(" ").count - 1
            let tabCount = linePrefix.componentsSeparatedByString("\t").count - 1

            if spaceCount > 0 && tabCount > 0 {
                violations.append(StyleViolation(
                    ruleDescription: IndentationRule.description,
                    severity: .Warning,
                    location: Location(file: file, characterOffset: line.range.location),
                    reason: "Code should be indented with tabs or 4 spaces, but not both."
                ))
            } else if spaceCount % 4 != 0 {
                violations.append(StyleViolation(
                    ruleDescription: IndentationRule.description,
                    severity: .Warning,
                    location: Location(file: file, characterOffset: line.range.location),
                    reason: "Code should be indented with tabs or 4 spaces, " +
                        "got \(spaceCount) spaces."
                ))
            }
        }

        return violations
    }
}
