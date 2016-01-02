//
//  LegacyConstructorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/11/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LegacyConstructorRule: CorrectableRule {

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
        ],
        triggeringExamples: [
            "↓CGPointMake(10, 10)",
            "↓CGSizeMake(10, 10)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGVectorMake(10, 10)",
            "↓NSMakeRange(10, 1)",
        ],
        corrections: [
            "CGPointMake(10,  10   )\n": "CGPointMake(x: 10, y: 10)\n",
            "CGSizeMake(10, 10)\n": "CGSizeMake(width: 10, height: 10)\n",
            "CGRectMake(0, 0, 10, 10)\n": "CGRectMake(x: 0, y: 0, width: 10, height: 10)\n",
            "CGVectorMake(10, 10)\n": "CGVectorMake(dx: 10, dy: 10)\n",
            "NSMakeRange(10, 1)\n": "NSMakeRange(loc: 10, len: 1)\n",
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

    public func correctFile(file: File) -> [Correction] {
        let number = "([\\-0-9\\.]+)"
        let twoNumbers = "\(number)\\s*,\\s*\(number)"
        let patterns = [
          "CGPointMake\\(\\s*\(twoNumbers)\\s*\\)": "CGPointMake(x: $1, y: $2)",
          "CGSizeMake\\(\\s*\(twoNumbers)\\s*\\)": "CGSizeMake(width: $1, height: $2)",
          "CGRectMake\\(\\s*\(twoNumbers)\\s*,\\s*\(twoNumbers)\\s*\\)":
              "CGRectMake(x: $1, y: $2, width: $3, height: $4)",
          "CGVectorMake\\(\\s*\(twoNumbers)\\s*\\)": "CGVectorMake(dx: $1, dy: $2)",
          "NSMakeRange\\(\\s*\(twoNumbers)\\s*\\)": "NSMakeRange(loc: $1, len: $2)",
        ]

        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents

        for (pattern, template) in patterns {
            let matches = file.matchPattern(pattern, excludingSyntaxKinds: [.Comment])

            let regularExpression = regex(pattern)
            for range in matches.reverse() {
              contents = regularExpression.stringByReplacingMatchesInString(contents,
                options: [], range: range, withTemplate: template)
              let location = Location(file: file, characterOffset: range.location)
              corrections.append(Correction(ruleDescription: description, location: location))
            }
        }

        file.write(contents)
        return corrections
    }
}
