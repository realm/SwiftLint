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

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "// \n" ],
        corrections: [ "// \n": "//\n" ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.filter {
            $0.content.hasTrailingWhitespace()
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file.path, line: $0.index))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        var correctedLines = [String]()
        var corrections = [Correction]()
        let fileRegions = file.regions()
        for line in file.lines {
            let correctedLine = (line.content as NSString)
                .stringByTrimmingTrailingCharactersInSet(whitespaceCharacterSet)
            let region = fileRegions.filter {
                $0.contains(Location(file: file.path, line: line.index, character: 0))
            }.first
            if region?.isRuleDisabled(self) == true {
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
