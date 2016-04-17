//
//  LegacyConstantRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyConstantRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_constant",
        name: "Legacy Constant",
        description: "Struct-scoped constants are preferred over legacy global constants.",
        nonTriggeringExamples: [
            "CGRect.infinite",
            "CGPoint.zero",
            "CGRect.zero",
            "CGSize.zero",
            "CGRect.null"
        ],
        triggeringExamples: [
            "↓CGRectInfinite",
            "↓CGPointZero",
            "↓CGRectZero",
            "↓CGSizeZero",
            "↓CGRectNull"
        ],
        corrections: [
            "↓CGRectInfinite\n": "CGRect.infinite\n",
            "↓CGPointZero\n": "CGPoint.zero\n",
            "↓CGRectZero\n": "CGRect.zero\n",
            "↓CGSizeZero\n": "CGSize.zero\n",
            "↓CGRectInfinite\n↓CGRectNull\n": "CGRect.infinite\nCGRect.null\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let constants = ["CGRectInfinite", "CGPointZero", "CGRectZero", "CGSizeZero",
            "CGRectNull"]

        let pattern = "\\b(" + constants.joinWithSeparator("|") + ")\\b"

        return file.matchPattern(pattern, withSyntaxKinds: [.Identifier]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let patterns = [
            "CGRectInfinite": "CGRect.infinite",
            "CGPointZero": "CGPoint.zero",
            "CGRectZero": "CGRect.zero",
            "CGSizeZero": "CGSize.zero",
            "CGRectNull": "CGRect.null"
        ]

        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents

        let matches = patterns.map {
                (pattern, template) -> [(NSRange, String, String)] in
                let matches = file.matchPattern(pattern, withSyntaxKinds: [.Identifier])
                return matches.map { ($0, pattern, template) }
            }
            .flatten()
            .sort { $0.0.location > $1.0.location } // reversed

        for (range, pattern, template) in matches {
            contents = regex(pattern).stringByReplacingMatchesInString(contents,
                options: [], range: range, withTemplate: template)
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
