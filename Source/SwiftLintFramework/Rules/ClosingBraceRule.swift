//
//  ClosingBraceRule.swift
//  SwiftLint
//
//  Created by Yasuhiro Inami on 12/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

extension File {
    fileprivate func violatingClosingBraceRanges() -> [NSRange] {
        return match(pattern: "(\\}[ \\t]+\\))", excludingSyntaxKinds: SyntaxKind.commentAndStringKinds())
    }
}

public struct ClosingBraceRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

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
            "[].map({ ↓}\t)"
        ],
        corrections: [
            "[].map({ ↓} )\n": "[].map({ })\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.violatingClosingBraceRanges().map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingClosingBraceRanges(), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "})")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
