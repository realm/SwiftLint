//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TrailingWhitespaceRule: CorrectableRule, ConfigurationProviderRule,
                                      SourceKitFreeRule {

    public var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                               ignoresComments: true)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace.",
        nonTriggeringExamples: [ "let name: String\n", "//\n", "// \n" ],
        triggeringExamples: [ "let name: String \n" ],
        corrections: [ "let name: String \n": "let name: String\n" ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let filteredLines = file.lines.filter {
            !(configuration.ignoresComments && $0.content.isComment()) &&
                $0.content.hasTrailingWhitespace() &&
                (!configuration.ignoresEmptyLines ||
                    // If configured, ignore lines that contain nothing but whitespace (empty lines)
                    !$0.content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).isEmpty)
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
            if configuration.ignoresComments && line.content.isComment() {
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
