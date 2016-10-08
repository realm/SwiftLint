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
            "NSPoint.zero",
            "NSRect.zero",
            "NSSize.zero",
            "CGRect.null"
        ],
        triggeringExamples: [
            "↓CGRectInfinite",
            "↓CGPointZero",
            "↓CGRectZero",
            "↓CGSizeZero",
            "↓NSZeroPoint",
            "↓NSZeroRect",
            "↓NSZeroSize",
            "↓CGRectNull"
        ],
        corrections: [
            "↓CGRectInfinite\n": "CGRect.infinite\n",
            "↓CGPointZero\n": "CGPoint.zero\n",
            "↓CGRectZero\n": "CGRect.zero\n",
            "↓CGSizeZero\n": "CGSize.zero\n",
            "↓NSZeroPoint\n": "NSPoint.zero\n",
            "↓NSZeroRect\n": "NSRect.zero\n",
            "↓NSZeroSize\n": "NSSize.zero\n",
            "↓CGRectInfinite\n↓CGRectNull\n": "CGRect.infinite\nCGRect.null\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let constants = ["CGRectInfinite", "CGPointZero", "CGRectZero", "CGSizeZero",
                         "NSZeroPoint", "NSZeroRect", "NSZeroSize", "CGRectNull"]

        let pattern = "\\b(" + constants.joined(separator: "|") + ")\\b"

        return file.matchPattern(pattern, withSyntaxKinds: [.Identifier]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let patterns = [
            "CGRectInfinite": "CGRect.infinite",
            "CGPointZero": "CGPoint.zero",
            "CGRectZero": "CGRect.zero",
            "CGSizeZero": "CGSize.zero",
            "NSZeroPoint": "NSPoint.zero",
            "NSZeroRect": "NSRect.zero",
            "NSZeroSize": "NSSize.zero",
            "CGRectNull": "CGRect.null"
        ]

        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents

        let matches = patterns.map({ pattern, template in
            file.matchPattern(pattern, withSyntaxKinds: [.Identifier])
                .map { ($0, pattern, template) }
        }).joined().sorted { $0.0.location > $1.0.location } // reversed

        for (range, pattern, template) in matches {
            contents = regex(pattern).stringByReplacingMatches(in: contents,
                                                                       options: [],
                                                                       range: range,
                                                                       withTemplate: template)
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
