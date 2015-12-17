//
//  OpeningBraceRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/21/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let violatingPattern = "((?:[^( ]|[\\t\\n\\f\\r (] )\\{)"
private let correctString = " {"

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension File {
    private func violatingOpeningBraceRanges() -> [NSRange] {
        return matchPattern(
            violatingPattern,
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct OpeningBraceRule: CorrectableRule {
    public static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration.",
        nonTriggeringExamples: [
            "func abc() {\n}",
            "[].map() { $0 }",
            "[].map({ })"
        ],
        triggeringExamples: [
            "func abc(){\n}",
            "func abc()\n\t{ }",
            "[].map(){ $0 }",
            "[].map( { } )"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingOpeningBraceRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let fileRegions = file.regions()
        let violatingRanges = file.violatingOpeningBraceRanges().filter { range in
            let region = fileRegions.filter {
                $0.contains(Location(file: file, offset: range.location))
            }.first
            return region?.isRuleEnabled(self) ?? true
        }

        let adjustedRanges = writeToFile(file, violatingRanges: violatingRanges)

        return adjustedRanges.map {
            Correction(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }

    private func writeToFile(file: File, violatingRanges: [NSRange]) -> [NSRange] {
        let correctStringCount = correctString.characters.count
        var correctedContents = file.contents
        var adjustedRanges = [NSRange]()
        var previousLengthDelta = 0

        for violatingRange in violatingRanges {
            guard let range = file.contents.nsrangeToIndexRange(violatingRange) else {
                continue
            }
            let capturedString = file.contents[range]
            let adjustedRange: NSRange

            if capturedString.characters.count == 2 &&
                capturedString.rangeOfCharacterFromSet(whitespaceAndNewlineCharacterSet) == nil {
                // if "struct Command{" is violated with violating string = "d{",
                // adjust range to only replace "{"
                adjustedRange = NSRange(
                    location: violatingRange.location - previousLengthDelta + 1,
                    length: correctStringCount - 1
                )
                previousLengthDelta = violatingRange.length - correctStringCount - 1
            } else {
                adjustedRange = NSRange(
                    location: violatingRange.location - previousLengthDelta,
                    length: correctStringCount
                )
                previousLengthDelta = violatingRange.length - correctStringCount
            }
            adjustedRanges += [adjustedRange]

            if let indexRange = correctedContents.nsrangeToIndexRange(adjustedRange) {
                correctedContents = correctedContents
                    .stringByReplacingCharactersInRange(indexRange, withString: correctString)
            }
        }

        file.write(correctedContents)

        return adjustedRanges
    }
}
