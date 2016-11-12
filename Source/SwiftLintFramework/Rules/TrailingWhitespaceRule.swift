//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TrailingWhitespaceRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                               ignoresComments: true)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace.",
        nonTriggeringExamples: [ "let name: String\n", "//\n", "// \n",
            "let name: String //\n", "let name: String // \n" ],
        triggeringExamples: [ "let name: String \n", "/* */ let name: String \n" ],
        corrections: [ "let name: String \n": "let name: String\n",
            "/* */ let name: String \n": "/* */ let name: String\n"]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let filteredLines = file.lines.filter {
            guard $0.content.hasTrailingWhitespace() else { return false }

            let commentKinds = SyntaxKind.commentKinds()
            if configuration.ignoresComments,
                let lastSyntaxKind = file.syntaxKindsByLines[$0.index].last
                where commentKinds.contains(lastSyntaxKind) {
                return false
            }

            return !configuration.ignoresEmptyLines ||
                // If configured, ignore lines that contain nothing but whitespace (empty lines)
                !$0.content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).isEmpty
        }

        return filteredLines.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file.path, line: $0.index))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        var correctedLines = [String]()
        var corrections = [Correction]()
        for line in file.lines {
            guard line.content.hasTrailingWhitespace() else {
                correctedLines.append(line.content)
                continue
            }

            let commentKinds = SyntaxKind.commentKinds()
            if configuration.ignoresComments,
                let lastSyntaxKind = file.syntaxKindsByLines[line.index].last
                where commentKinds.contains(lastSyntaxKind) {
                correctedLines.append(line.content)
                continue
            }

            let correctedLine = (line.content as NSString)
                .stringByTrimmingTrailingCharactersInSet(whitespaceCharacterSet)

            if configuration.ignoresEmptyLines && correctedLine.characters.isEmpty {
                correctedLines.append(line.content)
                continue
            }

            if file.ruleEnabledViolatingRanges([line.range], forRule: self).isEmpty {
                correctedLines.append(line.content)
                continue
            }

            if line.content != correctedLine {
                let description = self.dynamicType.description
                let location = Location(file: file.path, line: line.index)
                corrections.append(Correction(ruleDescription: description, location: location))
            }
            correctedLines.append(correctedLine)
        }
        if !corrections.isEmpty {
            // join and re-add trailing newline
            file.write(correctedLines.joinWithSeparator("\n") + "\n")
            return corrections
        }
        return []
    }
}
