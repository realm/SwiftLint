import Foundation
import SourceKittenFramework

public struct LegacyNSGeometryFunctionsRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_nsgeometry_functions",
        name: "Legacy NSGeometry Functions",
        description: "Struct extension properties and methods are preferred over legacy functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("rect.width"),
            Example("rect.height"),
            Example("rect.minX"),
            Example("rect.midX"),
            Example("rect.maxX"),
            Example("rect.minY"),
            Example("rect.midY"),
            Example("rect.maxY"),
            Example("rect.isEmpty"),
            Example("rect.integral"),
            Example("rect.insetBy(dx: 5.0, dy: -7.0)"),
            Example("rect.offsetBy(dx: 5.0, dy: -7.0)"),
            Example("rect1.union(rect2)"),
            Example("rect1.intersect(rect2)"),
            // "rect.divide(atDistance: 10.2, fromEdge: edge)", No correction available for divide
            Example("rect1.contains(rect2)"),
            Example("rect.contains(point)"),
            Example("rect1.intersects(rect2)")
        ],
        triggeringExamples: [
            Example("↓NSWidth(rect)"),
            Example("↓NSHeight(rect)"),
            Example("↓NSMinX(rect)"),
            Example("↓NSMidX(rect)"),
            Example("↓NSMaxX(rect)"),
            Example("↓NSMinY(rect)"),
            Example("↓NSMidY(rect)"),
            Example("↓NSMaxY(rect)"),
            Example("↓NSEqualRects(rect1, rect2)"),
            Example("↓NSEqualSizes(size1, size2)"),
            Example("↓NSEqualPoints(point1, point2)"),
            Example("↓NSEdgeInsetsEqual(insets2, insets2)"),
            Example("↓NSIsEmptyRect(rect)"),
            Example("↓NSIntegralRect(rect)"),
            Example("↓NSInsetRect(rect, 10, 5)"),
            Example("↓NSOffsetRect(rect, -2, 8.3)"),
            Example("↓NSUnionRect(rect1, rect2)"),
            Example("↓NSIntersectionRect(rect1, rect2)"),
            Example("↓NSContainsRect(rect1, rect2)"),
            Example("↓NSPointInRect(rect, point)"),
            Example("↓NSIntersectsRect(rect1, rect2)")
        ],
        corrections: [
            Example("↓NSWidth( rect  )\n"): Example("rect.width\n"),
            Example("↓NSHeight(rect )\n"): Example("rect.height\n"),
            Example("↓NSMinX( rect)\n"): Example("rect.minX\n"),
            Example("↓NSMidX(  rect)\n"): Example("rect.midX\n"),
            Example("↓NSMaxX( rect)\n"): Example("rect.maxX\n"),
            Example("↓NSMinY(rect   )\n"): Example("rect.minY\n"),
            Example("↓NSMidY(rect )\n"): Example("rect.midY\n"),
            Example("↓NSMaxY( rect     )\n"): Example("rect.maxY\n"),
            Example("↓NSEqualPoints( point1 , point2)\n"): Example("point1 == point2\n"),
            Example("↓NSEqualSizes(size1,size2   )\n"): Example("size1 == size2\n"),
            Example("↓NSEqualRects(  rect1,  rect2)\n"): Example("rect1 == rect2\n"),
            Example("↓NSEdgeInsetsEqual(insets1, insets2)\n"): Example("insets1 == insets2\n"),
            Example("↓NSIsEmptyRect( rect )\n"): Example("rect.isEmpty\n"),
            Example("↓NSIntegralRect(rect )\n"): Example("rect.integral\n"),
            Example("↓NSInsetRect(rect, 5.0, -7.0)\n"): Example("rect.insetBy(dx: 5.0, dy: -7.0)\n"),
            Example("↓NSOffsetRect(rect, -2, 8.3)\n"): Example("rect.offsetBy(dx: -2, dy: 8.3)\n"),
            Example("↓NSUnionRect(rect1, rect2)\n"): Example("rect1.union(rect2)\n"),
            Example("↓NSIntersectionRect( rect1 ,rect2)\n"): Example("rect1.intersect(rect2)\n"),
            Example("↓NSContainsRect( rect1,rect2     )\n"): Example("rect1.contains(rect2)\n"),
            Example("↓NSPointInRect(point  ,rect)\n"): Example("rect.contains(point)\n"), // note order of arguments
            Example("↓NSIntersectsRect(  rect1,rect2 )\n"): Example("rect1.intersects(rect2)\n"),
            Example("↓NSIntersectsRect(rect1, rect2 )\n↓NSWidth(rect  )\n"):
            Example("rect1.intersects(rect2)\nrect.width\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let functions = ["NSWidth", "NSHeight", "NSMinX", "NSMidX",
                         "NSMaxX", "NSMinY", "NSMidY", "NSMaxY",
                         "NSEqualRects", "NSEqualSizes", "NSEqualPoints", "NSEdgeInsetsEqual",
                         "NSIsEmptyRect", "NSIntegralRect", "NSInsetRect",
                         "NSOffsetRect", "NSUnionRect", "NSIntersectionRect",
                         "NSContainsRect", "NSPointInRect", "NSIntersectsRect"]

        let pattern = "\\b(" + functions.joined(separator: "|") + ")\\b"

        return file.match(pattern: pattern, with: [.identifier]).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
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
