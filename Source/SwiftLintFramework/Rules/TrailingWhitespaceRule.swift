//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
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

    public func validate(file: File) -> [StyleViolation] {
        let filteredLines = file.lines.filter {
            guard $0.content.hasTrailingWhitespace() else { return false }

            let commentKinds = SyntaxKind.commentKinds()
            if configuration.ignoresComments,
                let lastSyntaxKind = file.syntaxKindsByLines[$0.index].last,
                commentKinds.contains(lastSyntaxKind) {
                return false
            }

            return !configuration.ignoresEmptyLines ||
                    // If configured, ignore lines that contain nothing but whitespace (empty lines)
                    !$0.content.trimmingCharacters(in: .whitespaces).isEmpty
        }

        return filteredLines.map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file.path, line: $0.index))
        }
    }

    public func correct(file: File) -> [Correction] {
        let whitespaceCharacterSet = CharacterSet.whitespaces
        var correctedLines = [String]()
        var corrections = [Correction]()
        for line in file.lines {
            guard line.content.hasTrailingWhitespace() else {
                correctedLines.append(line.content)
                continue
            }

            let commentKinds = SyntaxKind.commentKinds()
            if configuration.ignoresComments,
                let lastSyntaxKind = file.syntaxKindsByLines[line.index].last,
                commentKinds.contains(lastSyntaxKind) {
                correctedLines.append(line.content)
                continue
            }

            let correctedLine = line.content.bridge()
                .trimmingTrailingCharacters(in: whitespaceCharacterSet)

            if configuration.ignoresEmptyLines && correctedLine.characters.isEmpty {
                correctedLines.append(line.content)
                continue
            }

            if file.ruleEnabled(violatingRanges: [line.range], for: self).isEmpty {
                correctedLines.append(line.content)
                continue
            }

            if line.content != correctedLine {
                let description = type(of: self).description
                let location = Location(file: file.path, line: line.index)
                corrections.append(Correction(ruleDescription: description, location: location))
            }
            correctedLines.append(correctedLine)
        }
        if !corrections.isEmpty {
            // join and re-add trailing newline
            file.write(correctedLines.joined(separator: "\n") + "\n")
            return corrections
        }
        return []
    }
}
