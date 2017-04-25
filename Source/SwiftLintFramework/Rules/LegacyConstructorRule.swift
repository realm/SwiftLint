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

    public var configuration = SeverityConfiguration(.warning)

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
            "NSPoint(x: 10, y: 10)",
            "NSPoint(x: xValue, y: yValue)",
            "NSSize(width: 10, height: 10)",
            "NSSize(width: aWidth, height: aHeight)",
            "NSRect(x: 0, y: 0, width: 10, height: 10)",
            "NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "NSRange(location: 10, length: 1)",
            "NSRange(location: loc, length: len)",
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
            "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"
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
            "↓NSMakePoint(10, 10)",
            "↓NSMakePoint(xVal, yVal)",
            "↓NSMakeSize(10, 10)",
            "↓NSMakeSize(aWidth, aHeight)",
            "↓NSMakeRect(0, 0, 10, 10)",
            "↓NSMakeRect(xVal, yVal, width, height)",
            "↓NSMakeRange(10, 1)",
            "↓NSMakeRange(loc, len)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)",
            "↓UIEdgeInsetsMake(top, left, bottom, right)",
            "↓NSEdgeInsetsMake(0, 0, 10, 10)",
            "↓NSEdgeInsetsMake(top, left, bottom, right)"
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
            "↓NSMakePoint(10,  10   )\n": "NSPoint(x: 10, y: 10)\n",
            "↓NSMakePoint(xPos,  yPos   )\n": "NSPoint(x: xPos, y: yPos)\n",
            "↓NSMakeSize(10, 10)\n": "NSSize(width: 10, height: 10)\n",
            "↓NSMakeSize( aWidth, aHeight )\n": "NSSize(width: aWidth, height: aHeight)\n",
            "↓NSMakeRect(0, 0, 10, 10)\n": "NSRect(x: 0, y: 0, width: 10, height: 10)\n",
            "↓NSMakeRect(xPos, yPos , width, height)\n":
            "NSRect(x: xPos, y: yPos, width: width, height: height)\n",
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
            "↓NSEdgeInsetsMake(0, 0, 10, 10)\n":
            "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n",
            "↓NSEdgeInsetsMake(top, left, bottom, right)\n":
            "NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let constructors = ["CGRectMake", "CGPointMake", "CGSizeMake", "CGVectorMake",
                            "NSMakePoint", "NSMakeSize", "NSMakeRect", "NSMakeRange",
                            "UIEdgeInsetsMake", "NSEdgeInsetsMake"]

        let pattern = "\\b(" + constructors.joined(separator: "|") + ")\\b"

        return file.match(pattern: pattern, with: [.identifier]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let twoVarsOrNum = RegexHelpers.twoVariableOrNumber
        let patterns = [
            "CGPointMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGPoint(x: $1, y: $2)",
            "CGSizeMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGSize(width: $1, height: $2)",
            "CGRectMake\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "CGRect(x: $1, y: $2, width: $3, height: $4)",
            "CGVectorMake\\(\\s*\(twoVarsOrNum)\\s*\\)": "CGVector(dx: $1, dy: $2)",
            "NSMakePoint\\(\\s*\(twoVarsOrNum)\\s*\\)": "NSPoint(x: $1, y: $2)",
            "NSMakeSize\\(\\s*\(twoVarsOrNum)\\s*\\)": "NSSize(width: $1, height: $2)",
            "NSMakeRect\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "NSRect(x: $1, y: $2, width: $3, height: $4)",
            "NSMakeRange\\(\\s*\(twoVarsOrNum)\\s*\\)": "NSRange(location: $1, length: $2)",
            "UIEdgeInsetsMake\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "UIEdgeInsets(top: $1, left: $2, bottom: $3, right: $4)",
            "NSEdgeInsetsMake\\(\\s*\(twoVarsOrNum)\\s*,\\s*\(twoVarsOrNum)\\s*\\)":
            "NSEdgeInsets(top: $1, left: $2, bottom: $3, right: $4)"
        ]
        return file.correct(legacyRule: self, patterns: patterns)
    }
}
