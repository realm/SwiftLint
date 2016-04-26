//
//  LegacyConstructorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/11/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyConstructorRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

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
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
        ],
        triggeringExamples: [
            "↓CGPointMake(10, 10)",
            "↓CGSizeMake(10, 10)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGVectorMake(10, 10)",
            "↓NSMakeRange(10, 1)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)",
        ],
        corrections: [
            "↓CGPointMake(10,  10   )\n": "CGPoint(x: 10, y: 10)\n",
            "↓CGSizeMake(10, 10)\n": "CGSize(width: 10, height: 10)\n",
            "↓CGRectMake(0, 0, 10, 10)\n": "CGRect(x: 0, y: 0, width: 10, height: 10)\n",
            "↓CGVectorMake(10, 10)\n": "CGVector(dx: 10, dy: 10)\n",
            "↓NSMakeRange(10, 1)\n": "NSRange(location: 10, length: 1)\n",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)\n": "CGVector(dx: 10, dy: 10)\n" +
                "NSRange(location: 10, length: 1)\n",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)\n":
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let constructors = ["CGRectMake", "CGPointMake", "CGSizeMake", "CGVectorMake",
            "NSMakeRange", "UIEdgeInsetsMake"]

        let pattern = "\\b(" + constructors.joinWithSeparator("|") + ")\\b"

        return file.matchPattern(pattern, withSyntaxKinds: [.Identifier]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let number = "([\\-0-9\\.]+)"
        let twoNumbers = "\(number)\\s*,\\s*\(number)"
        let patterns = [
            "CGPointMake\\(\\s*\(twoNumbers)\\s*\\)": "CGPoint(x: $1, y: $2)",
            "CGSizeMake\\(\\s*\(twoNumbers)\\s*\\)": "CGSize(width: $1, height: $2)",
            "CGRectMake\\(\\s*\(twoNumbers)\\s*,\\s*\(twoNumbers)\\s*\\)":
            "CGRect(x: $1, y: $2, width: $3, height: $4)",
            "CGVectorMake\\(\\s*\(twoNumbers)\\s*\\)": "CGVector(dx: $1, dy: $2)",
            "NSMakeRange\\(\\s*\(twoNumbers)\\s*\\)": "NSRange(location: $1, length: $2)",
            "UIEdgeInsetsMake\\(\\s*\(twoNumbers)\\s*,\\s*\(twoNumbers)\\s*\\)":
            "UIEdgeInsets(top: $1, left: $2, bottom: $3, right: $4)",
        ]

        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents

        let matches = patterns.map {
                (pattern, template) -> [(NSRange, String, String)] in
                let matches = file.matchPattern(pattern)
                    .filter { $0.1.first == .Identifier }
                    .map { ($0.0, pattern, template) }
                return matches
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
