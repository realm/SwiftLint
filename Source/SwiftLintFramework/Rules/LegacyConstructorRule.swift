//
//  LegacyConstructorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/11/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LegacyConstructorRule: Rule {
    public static let description = RuleDescription(
        identifier: "legacy_constructor",
        name: "Legacy Constructor",
        description: "Swift constructors are preferred over legacy convenience functions.",
        nonTriggeringExamples: [
            "CGPoint(x: 10, y: 10)",
            "CGSize(width: 10, height: 10)",
            "CGRect(x: 0, y: 0, width: 10, height: 10)",
            "CGVector(dx: 10, dy: 10)",
            "NSRange(location: 10, length: 1)",
        ],
        triggeringExamples: [
            "↓CGPointMake(10, 10)",
            "↓CGSizeMake(10, 10)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGVectorMake(10, 10)",
            "↓NSMakeRange(10, 1)",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let constructors = ["CGRectMake", "CGPointMake", "CGSizeMake", "CGVectorMake",
            "NSMakeRange"]

        let pattern = "\\b(" + constructors.joinWithSeparator("|") + ")\\b"

        return file.matchPattern(pattern, withSyntaxKinds: [.Identifier]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }
}
