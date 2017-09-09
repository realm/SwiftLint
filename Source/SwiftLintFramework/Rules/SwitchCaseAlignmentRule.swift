//
//  SwitchCaseAlignmentRule.swift
//  SwiftLint
//
//  Created by Austin Lu on 9/6/17.
//  Copyright © 2017 Realm. All rights reserved.
//


import Foundation
import SourceKittenFramework

public struct SwitchCaseAlignmentRule: OptInRule, ConfigurationProviderRule {
    private static let caseKeyword = "case"
    private static let defaultKeyword = "default"
    private static let switchKeyword = "switch"

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: "Case statements should vertically align with the enclosing switch statement itself.",
        kind: .style,
        nonTriggeringExamples: [
            "switch someBool {\n" +
            "case true: // case 1\n" +
            "    print('red')\n" +
            "case false:\n" +
            "    /*\n" +
            "    case 2\n" +
            "    */\n" +
            "    if case let .someEnum(val) = someFunc() {\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}",
            "if aBool {\n" +
            "    switch someBool {\n" +
            "    case true:\n" +
            "        print('red')\n" +
            "    case false:\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}",
            "switch someInt {\n" +
            "// comments ignored\n" +
            "case 0:\n" +
            "    // zero case\n" +
            "    print('Zero')\n" +
            "case 1:\n" +
            "    print('One')\n" +
            "default:\n" +
            "    print('Some other number')\n" +
            "}"
        ],
        triggeringExamples: [
            "switch someBool {\n" +
            "    ↓case true:\n" +
            "         print('red')\n" +
            "    ↓case false:\n" +
            "         print('blue')\n" +
            "}",
            "if aBool {\n" +
            "    switch someBool {\n" +
            "        ↓case true:\n" +
            "            print('red')\n" +
            "    case false:\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}",
            "switch someInt {\n" +
            "    ↓case 0:\n" +
            "    print('Zero')\n" +
            "case 1:\n" +
            "    print('One')\n" +
            "    ↓default:\n" +
            "    print('Some other number')\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var indentsOnEnclosingSwitch = -1

        for line in file.lines {
            let content = line.content
            // cache the indentation of any `switch` statement
            if let range = range(for: SwitchCaseAlignmentRule.switchKeyword, line: line, file: file) {
                indentsOnEnclosingSwitch = content.distance(from: content.startIndex, to: range.lowerBound)
            }
            // check alignment of any `case` and `default` statements
            validateAlignment(for: SwitchCaseAlignmentRule.caseKeyword,
                              line: line,
                              file: file,
                              expectedIndents: indentsOnEnclosingSwitch).flatMap { violations.append($0) }
            validateAlignment(for: SwitchCaseAlignmentRule.defaultKeyword,
                              line: line,
                              file: file,
                              expectedIndents: indentsOnEnclosingSwitch).flatMap { violations.append($0) }
        }
        return violations
    }

    // Attempt to find a keyword's range within a given line, excluding comments and strings
    private func range(for keyword: String, line: Line, file: File) -> Range<String.Index>? {
        let content = line.content
        // exclude occurances of keyword in comments and strings
        let filteredMatches = file.match(pattern: "\\s*\(keyword)",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds(),
            range: line.range)
        if !filteredMatches.isEmpty &&
            content.trimmingCharacters(in: .whitespaces).hasPrefix(keyword) {
            return content.range(of: keyword)
        }
        return nil
    }

    // Returns a `StyleViolation` if the keyword is present and does not align with the expected indentation
    private func validateAlignment(for keyword: String,
                                   line: Line,
                                   file: File,
                                   expectedIndents: Int) -> StyleViolation? {
        let content = line.content
        if let range = range(for: keyword, line: line, file: file) {
            let keywordIndents = content.distance(from: content.startIndex, to: range.lowerBound)
            if keywordIndents != expectedIndents {
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, characterOffset: line.range.location + keywordIndents))
            }
        }
        // keyword isn't present in a non-comment and non-string type
        return nil
    }
}
