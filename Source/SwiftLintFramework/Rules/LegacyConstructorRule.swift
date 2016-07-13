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
            "CGPoint(x: xValue, y: yValue)",
            "CGSize(width: 10, height: 10)",
            "CGSize(width: aWidth, height: aHeight)",
            "CGRect(x: 0, y: 0, width: 10, height: 10)",
            "CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "CGVector(dx: 10, dy: 10)",
            "CGVector(dx: deltaX, dy: deltaY)",
            "NSRange(location: 10, length: 1)",
            "NSRange(location: loc, length: len)",
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
        ],
        triggeringExamples: [
            "↓CGPointMake(10, 10)",
            "↓CGPointMake(xVal, yVal)",
            "↓CGSizeMake(10, 10)",
            "↓CGSizeMake(aWidth, aHeight)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGRectMake(xVal, yVal, width, height)",
            "↓CGVectorMake(10, 10)",
            "↓CGVectorMake(deltaX, deltaY)",
            "↓NSMakeRange(10, 1)",
            "↓NSMakeRange(loc, len)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)",
            "↓UIEdgeInsetsMake(top, left, bottom, right)",
        ],
        corrections: [
            "↓CGPointMake(10,  10   )\n": "CGPoint(x: 10, y: 10)\n",
            "↓CGPointMake(xPos,  yPos   )\n": "CGPoint(x: xPos, y: yPos)\n",
            "↓CGSizeMake(10, 10)\n": "CGSize(width: 10, height: 10)\n",
            "↓CGSizeMake( aWidth, aHeight )\n": "CGSize(width: aWidth, height: aHeight)\n",
            "↓CGRectMake(0, 0, 10, 10)\n": "CGRect(x: 0, y: 0, width: 10, height: 10)\n",
            "↓CGRectMake(xPos, yPos , width, height)\n":
            "CGRect(x: xPos, y: yPos, width: width, height: height)\n",
            "↓CGVectorMake(10, 10)\n": "CGVector(dx: 10, dy: 10)\n",
            "↓CGVectorMake(deltaX, deltaY)\n": "CGVector(dx: deltaX, dy: deltaY)\n",
            "↓NSMakeRange(10, 1)\n": "NSRange(location: 10, length: 1)\n",
            "↓NSMakeRange(loc, len)\n": "NSRange(location: loc, length: len)\n",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)\n": "CGVector(dx: 10, dy: 10)\n" +
                "NSRange(location: 10, length: 1)\n",
            "↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)\n": "CGVector(dx: dx, dy: dy)\n" +
            "NSRange(location: loc, length: len)\n",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)\n":
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n",
            "↓UIEdgeInsetsMake(top, left, bottom, right)\n":
            "UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n",
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
        if isRuleDisabled(file) {
            return []
        }
        let twoVarsOrNum = RegexHelpers.twoVariableOrNumber

        let patterns = [
            "CGPointMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGPoint(x: $1, y: $2)",
            "CGSizeMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGSize(width: $1, height: $2)",
            "CGRectMake\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "CGRect(x: $1, y: $2, width: $3, height: $4)",
            "CGVectorMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGVector(dx: $1, dy: $2)",
            "NSMakeRange\\(\\s*\(twoVarsOrNum)\\s*\\)": "NSRange(location: $1, length: $2)",
            "UIEdgeInsetsMake\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "UIEdgeInsets(top: $1, left: $2, bottom: $3, right: $4)",
        ]

        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents

        let matches = patterns.map({ pattern, template in
            file.matchPattern(pattern)
                .filter { $0.1.first == .Identifier }
                .map { ($0.0, pattern, template) }
        }).flatten().sort { $0.0.location > $1.0.location } // reversed

        for (range, pattern, template) in matches {
            contents = regex(pattern).stringByReplacingMatchesInString(contents,
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
