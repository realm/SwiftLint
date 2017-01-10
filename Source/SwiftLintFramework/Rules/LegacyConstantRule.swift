//
//  LegacyConstantRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyConstantRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

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

    public func validate(file: File) -> [StyleViolation] {
        let constants = ["CGRectInfinite", "CGPointZero", "CGRectZero", "CGSizeZero",
                         "NSZeroPoint", "NSZeroRect", "NSZeroSize", "CGRectNull"]

        let pattern = "\\b(" + constants.joined(separator: "|") + ")\\b"

        return file.match(pattern: pattern, with: [.identifier]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
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
        return file.correct(legacyRule: self, patterns: patterns)
    }
}
