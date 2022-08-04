import Foundation
import SourceKittenFramework

public struct LegacyCGGeometryFunctionsRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_cggeometry_functions",
        name: "Legacy CGGeometry Functions",
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
            Example("rect.isNull"),
            Example("rect.isEmpty"),
            Example("rect.isInfinite"),
            Example("rect.standardized"),
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
            Example("↓CGRectGetWidth(rect)"),
            Example("↓CGRectGetHeight(rect)"),
            Example("↓CGRectGetMinX(rect)"),
            Example("↓CGRectGetMidX(rect)"),
            Example("↓CGRectGetMaxX(rect)"),
            Example("↓CGRectGetMinY(rect)"),
            Example("↓CGRectGetMidY(rect)"),
            Example("↓CGRectGetMaxY(rect)"),
            Example("↓CGRectIsNull(rect)"),
            Example("↓CGRectIsEmpty(rect)"),
            Example("↓CGRectIsInfinite(rect)"),
            Example("↓CGRectStandardize(rect)"),
            Example("↓CGRectIntegral(rect)"),
            Example("↓CGRectInset(rect, 10, 5)"),
            Example("↓CGRectOffset(rect, -2, 8.3)"),
            Example("↓CGRectUnion(rect1, rect2)"),
            Example("↓CGRectIntersection(rect1, rect2)"),
            Example("↓CGRectContainsRect(rect1, rect2)"),
            Example("↓CGRectContainsPoint(rect, point)"),
            Example("↓CGRectIntersectsRect(rect1, rect2)")
        ],
        corrections: [
            Example("↓CGRectGetWidth( rect  )\n"): Example("rect.width\n"),
            Example("↓CGRectGetHeight(rect )\n"): Example("rect.height\n"),
            Example("↓CGRectGetMinX( rect)\n"): Example("rect.minX\n"),
            Example("↓CGRectGetMidX(  rect)\n"): Example("rect.midX\n"),
            Example("↓CGRectGetMaxX( rect)\n"): Example("rect.maxX\n"),
            Example("↓CGRectGetMinY(rect   )\n"): Example("rect.minY\n"),
            Example("↓CGRectGetMidY(rect )\n"): Example("rect.midY\n"),
            Example("↓CGRectGetMaxY( rect     )\n"): Example("rect.maxY\n"),
            Example("↓CGRectIsNull(  rect    )\n"): Example("rect.isNull\n"),
            Example("↓CGRectIsEmpty( rect )\n"): Example("rect.isEmpty\n"),
            Example("↓CGRectIsInfinite( rect )\n"): Example("rect.isInfinite\n"),
            Example("↓CGRectStandardize( rect)\n"): Example("rect.standardized\n"),
            Example("↓CGRectIntegral(rect )\n"): Example("rect.integral\n"),
            Example("↓CGRectInset(rect, 5.0, -7.0)\n"): Example("rect.insetBy(dx: 5.0, dy: -7.0)\n"),
            Example("↓CGRectOffset(rect, -2, 8.3)\n"): Example("rect.offsetBy(dx: -2, dy: 8.3)\n"),
            Example("↓CGRectUnion(rect1, rect2)\n"): Example("rect1.union(rect2)\n"),
            Example("↓CGRectIntersection( rect1 ,rect2)\n"): Example("rect1.intersect(rect2)\n"),
            Example("↓CGRectContainsRect( rect1,rect2     )\n"): Example("rect1.contains(rect2)\n"),
            Example("↓CGRectContainsPoint(rect  ,point)\n"): Example("rect.contains(point)\n"),
            Example("↓CGRectIntersectsRect(  rect1,rect2 )\n"): Example("rect1.intersects(rect2)\n"),
            Example("↓CGRectIntersectsRect(rect1, rect2 )\n↓CGRectGetWidth(rect  )\n"):
                Example("rect1.intersects(rect2)\nrect.width\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let functions = ["CGRectGetWidth", "CGRectGetHeight", "CGRectGetMinX", "CGRectGetMidX",
                         "CGRectGetMaxX", "CGRectGetMinY", "CGRectGetMidY", "CGRectGetMaxY",
                         "CGRectIsNull", "CGRectIsEmpty", "CGRectIsInfinite", "CGRectStandardize",
                         "CGRectIntegral", "CGRectInset", "CGRectOffset", "CGRectUnion",
                         "CGRectIntersection", "CGRectContainsRect", "CGRectContainsPoint",
                         "CGRectIntersectsRect"]

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
            "CGRectGetWidth\\(\(varName)\\)": "$1.width",
            "CGRectGetHeight\\(\(varName)\\)": "$1.height",
            "CGRectGetMinX\\(\(varName)\\)": "$1.minX",
            "CGRectGetMidX\\(\(varName)\\)": "$1.midX",
            "CGRectGetMaxX\\(\(varName)\\)": "$1.maxX",
            "CGRectGetMinY\\(\(varName)\\)": "$1.minY",
            "CGRectGetMidY\\(\(varName)\\)": "$1.midY",
            "CGRectGetMaxY\\(\(varName)\\)": "$1.maxY",
            "CGRectIsNull\\(\(varName)\\)": "$1.isNull",
            "CGRectIsEmpty\\(\(varName)\\)": "$1.isEmpty",
            "CGRectIsInfinite\\(\(varName)\\)": "$1.isInfinite",
            "CGRectStandardize\\(\(varName)\\)": "$1.standardized",
            "CGRectIntegral\\(\(varName)\\)": "$1.integral",
            "CGRectInset\\(\(varName),\(twoVariableOrNumber)\\)": "$1.insetBy(dx: $2, dy: $3)",
            "CGRectOffset\\(\(varName),\(twoVariableOrNumber)\\)": "$1.offsetBy(dx: $2, dy: $3)",
            "CGRectUnion\\(\(twoVars)\\)": "$1.union($2)",
            "CGRectIntersection\\(\(twoVars)\\)": "$1.intersect($2)",
            "CGRectContainsRect\\(\(twoVars)\\)": "$1.contains($2)",
            "CGRectContainsPoint\\(\(twoVars)\\)": "$1.contains($2)",
            "CGRectIntersectsRect\\(\(twoVars)\\)": "$1.intersects($2)"
        ]
        return file.correct(legacyRule: self, patterns: patterns)
    }
}
