//
//  OpeningBraceRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/21/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension File {
    private func violatingOpeningBraceRanges() -> [NSRange] {
        return matchPattern(
            "((?:[^( ]|[\\s(][\\s]+)\\{)",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct OpeningBraceRule: CorrectableRule {

    public init() {}

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
            "func abc(↓){\n}",
            "func abc()↓\n\t{ }",
            "[].map(↓){ $0 }",
            "[].map↓( { } )"
        ],
        corrections: [
            "struct Rule{}\n": "struct Rule {}\n",
            "struct Rule\n{\n}\n": "struct Rule {\n}\n",
            "struct Rule\n\n\t{\n}\n": "struct Rule {\n}\n",
            "struct Parent {\n\tstruct Child\n\t{\n\t\tlet foo: Int\n\t}\n}\n":
                "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n",
            "[].map(){ $0 }\n": "[].map() { $0 }\n",
            "[].map( { })\n": "[].map({ })\n",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingOpeningBraceRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabledViolatingRanges(
            file.violatingOpeningBraceRanges(),
            forRule: self
        )
        return writeToFile(file, violatingRanges: violatingRanges)
    }

    private func writeToFile(file: File, violatingRanges: [NSRange]) -> [Correction] {
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reverse() {
            let (contents, adjustedRange) =
            correctContents(correctedContents, violatingRange: violatingRange)

            correctedContents = contents
            if let adjustedRange = adjustedRange {
                adjustedLocations.insert(adjustedRange.location, atIndex: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0))
        }
    }

    private func correctContents(contents: String, violatingRange: NSRange)
        -> (correctedContents: String, adjustedRange: NSRange?) {
        guard let indexRange = contents.nsrangeToIndexRange(violatingRange) else {
            return (contents, nil)
        }
        let capturedString = contents[indexRange]
        var adjustedRange = violatingRange
        var correctString = " {"

        // "struct Command{" has violating string = "d{", so ignore first "d"
        if capturedString.characters.count == 2 &&
            capturedString.rangeOfCharacterFromSet(whitespaceAndNewlineCharacterSet) == nil {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
        }

        // "[].map( { } )" has violating string = "( {",
        // so ignore first "(" and use "{" as correction string instead
        if capturedString.hasPrefix("(") {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
            correctString = "{"
        }

        if let indexRange = contents.nsrangeToIndexRange(adjustedRange) {
            let correctedContents = contents
                .stringByReplacingCharactersInRange(indexRange, withString: correctString)
            return (correctedContents, adjustedRange)
        } else {
            return (contents, nil)
        }
    }
}
