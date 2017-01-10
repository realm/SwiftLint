//
//  LegacyNSGeometryFunctionsRule.swift
//  SwiftLint
//
//  Created by David Rönnqvist on 01/08/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyNSGeometryFunctionsRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_nsgeometry_functions",
        name: "Legacy NSGeometry Functions",
        description: "Struct extension properties and methods are preferred over legacy functions",
        nonTriggeringExamples: [
            "rect.width",
            "rect.height",
            "rect.minX",
            "rect.midX",
            "rect.maxX",
            "rect.minY",
            "rect.midY",
            "rect.maxY",
            "rect.isEmpty",
            "rect.integral",
            "rect.insetBy(dx: 5.0, dy: -7.0)",
            "rect.offsetBy(dx: 5.0, dy: -7.0)",
            "rect1.union(rect2)",
            "rect1.intersect(rect2)",
            // "rect.divide(atDistance: 10.2, fromEdge: edge)", No correction available for divide
            "rect1.contains(rect2)",
            "rect.contains(point)",
            "rect1.intersects(rect2)"
        ],
        triggeringExamples: [
            "↓NSWidth(rect)",
            "↓NSHeight(rect)",
            "↓NSMinX(rect)",
            "↓NSMidX(rect)",
            "↓NSMaxX(rect)",
            "↓NSMinY(rect)",
            "↓NSMidY(rect)",
            "↓NSMaxY(rect)",
            "↓NSEqualRects(rect1, rect2)",
            "↓NSEqualSizes(size1, size2)",
            "↓NSEqualPoints(point1, point2)",
            "↓NSEdgeInsetsEqual(insets2, insets2)",
            "↓NSIsEmptyRect(rect)",
            "↓NSIntegralRect(rect)",
            "↓NSInsetRect(rect, 10, 5)",
            "↓NSOffsetRect(rect, -2, 8.3)",
            "↓NSUnionRect(rect1, rect2)",
            "↓NSIntersectionRect(rect1, rect2)",
            "↓NSContainsRect(rect1, rect2)",
            "↓NSPointInRect(rect, point)",
            "↓NSIntersectsRect(rect1, rect2)"
        ],
        corrections: [
            "↓NSWidth( rect  )\n": "rect.width\n",
            "↓NSHeight(rect )\n": "rect.height\n",
            "↓NSMinX( rect)\n": "rect.minX\n",
            "↓NSMidX(  rect)\n": "rect.midX\n",
            "↓NSMaxX( rect)\n": "rect.maxX\n",
            "↓NSMinY(rect   )\n": "rect.minY\n",
            "↓NSMidY(rect )\n": "rect.midY\n",
            "↓NSMaxY( rect     )\n": "rect.maxY\n",
            "↓NSEqualPoints( point1 , point2)\n": "point1 == point2\n",
            "↓NSEqualSizes(size1,size2   )\n": "size1 == size2\n",
            "↓NSEqualRects(  rect1,  rect2)\n": "rect1 == rect2\n",
            "↓NSEdgeInsetsEqual(insets1, insets2)\n": "insets1 == insets2\n",
            "↓NSIsEmptyRect( rect )\n": "rect.isEmpty\n",
            "↓NSIntegralRect(rect )\n": "rect.integral\n",
            "↓NSInsetRect(rect, 5.0, -7.0)\n": "rect.insetBy(dx: 5.0, dy: -7.0)\n",
            "↓NSOffsetRect(rect, -2, 8.3)\n": "rect.offsetBy(dx: -2, dy: 8.3)\n",
            "↓NSUnionRect(rect1, rect2)\n": "rect1.union(rect2)\n",
            "↓NSIntersectionRect( rect1 ,rect2)\n": "rect1.intersect(rect2)\n",
            "↓NSContainsRect( rect1,rect2     )\n": "rect1.contains(rect2)\n",
            "↓NSPointInRect(point  ,rect)\n": "rect.contains(point)\n", // note order of arguments
            "↓NSIntersectsRect(  rect1,rect2 )\n": "rect1.intersects(rect2)\n",
            "↓NSIntersectsRect(rect1, rect2 )\n↓NSWidth(rect  )\n":
            "rect1.intersects(rect2)\nrect.width\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let functions = ["NSWidth", "NSHeight", "NSMinX", "NSMidX",
                         "NSMaxX", "NSMinY", "NSMidY", "NSMaxY",
                         "NSEqualRects", "NSEqualSizes", "NSEqualPoints", "NSEdgeInsetsEqual",
                         "NSIsEmptyRect", "NSIntegralRect", "NSInsetRect",
                         "NSOffsetRect", "NSUnionRect", "NSIntersectionRect",
                         "NSContainsRect", "NSPointInRect", "NSIntersectsRect"]

        let pattern = "\\b(" + functions.joined(separator: "|") + ")\\b"

        return file.match(pattern: pattern, with: [.identifier]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let varName = RegexHelpers.varNameGroup
        let twoVars = RegexHelpers.twoVars
        let twoVariableOrNumber = RegexHelpers.twoVariableOrNumber
        let patterns: [String: String] = [
            "NSWidth\\(\(varName)\\)": "$1.width",
            "NSHeight\\(\(varName)\\)": "$1.height",
            "NSMinX\\(\(varName)\\)": "$1.minX",
            "NSMidX\\(\(varName)\\)": "$1.midX",
            "NSMaxX\\(\(varName)\\)": "$1.maxX",
            "NSMinY\\(\(varName)\\)": "$1.minY",
            "NSMidY\\(\(varName)\\)": "$1.midY",
            "NSMaxY\\(\(varName)\\)": "$1.maxY",
            "NSEqualRects\\(\(twoVars)\\)": "$1 == $2",
            "NSEqualSizes\\(\(twoVars)\\)": "$1 == $2",
            "NSEqualPoints\\(\(twoVars)\\)": "$1 == $2",
            "NSEdgeInsetsEqual\\(\(twoVars)\\)": "$1 == $2",
            "NSIsEmptyRect\\(\(varName)\\)": "$1.isEmpty",
            "NSIntegralRect\\(\(varName)\\)": "$1.integral",
            "NSInsetRect\\(\(varName),\(twoVariableOrNumber)\\)": "$1.insetBy(dx: $2, dy: $3)",
            "NSOffsetRect\\(\(varName),\(twoVariableOrNumber)\\)": "$1.offsetBy(dx: $2, dy: $3)",
            "NSUnionRect\\(\(twoVars)\\)": "$1.union($2)",
            "NSIntersectionRect\\(\(twoVars)\\)": "$1.intersect($2)",
            "NSContainsRect\\(\(twoVars)\\)": "$1.contains($2)",
            "NSPointInRect\\(\(twoVars)\\)": "$2.contains($1)", // note order of arguments
            "NSIntersectsRect\\(\(twoVars)\\)": "$1.intersects($2)"
        ]
        return file.correct(legacyRule: self, patterns: patterns)
    }
}
