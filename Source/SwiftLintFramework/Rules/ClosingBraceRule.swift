//
//  ClosingBraceRule.swift
//  SwiftLint
//
//  Created by Yasuhiro Inami on 2015-12-19.
//  Copyright © 2015 Yasuhiro Inami. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension File {
    private func violatingClosingBraceRanges() -> [NSRange] {
        return matchPattern(
            "(\\}[ \\t]+\\))",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct ClosingBraceRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closing_brace",
        name: "Closing Brace Spacing",
        description: "Closing brace with closing parenthesis " +
                     "should not have any whitespaces in the middle.",
        nonTriggeringExamples: [
            "[].map({ })",
            "[].map(\n  { }\n)"
        ],
        triggeringExamples: [
            "[].map({ ↓} )",
            "[].map({ }\t)"
        ],
        corrections: [
            "[].map({ } )\n": "[].map({ })\n"
        ]
    )


    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingClosingBraceRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabledViolatingRanges(
            file.violatingClosingBraceRanges(),
            forRule: self
        )
        return writeToFile(file, violatingRanges: violatingRanges)
    }

    private func writeToFile(file: File, violatingRanges: [NSRange]) -> [Correction] {
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reverse() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .stringByReplacingCharactersInRange(indexRange, withString: "})")
                adjustedLocations.insert(violatingRange.location, atIndex: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0))
        }
    }
}
