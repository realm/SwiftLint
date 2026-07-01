import SwiftLintCore

@SwiftSyntaxRule(explicitRewriter: true)
struct LegacyCGGeometryFunctionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_cggeometry_functions",
        name: "Legacy CGGeometry Functions",
        description: "Struct extension properties and methods are preferred over legacy functions",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "rect.width",
            "rect.height",
            "rect.minX",
            "rect.midX",
            "rect.maxX",
            "rect.minY",
            "rect.midY",
            "rect.maxY",
            "rect.isNull",
            "rect.isEmpty",
            "rect.isInfinite",
            "rect.standardized",
            "rect.integral",
            "rect.insetBy(dx: 5.0, dy: -7.0)",
            "rect.offsetBy(dx: 5.0, dy: -7.0)",
            "rect1.union(rect2)",
            "rect1.intersect(rect2)",
            // "rect.divide(atDistance: 10.2, fromEdge: edge)", No correction available for divide
            "rect1.contains(rect2)",
            "rect.contains(point)",
            "rect1.intersects(rect2)",
        ]),
        triggeringExamples: #examples([
            "↓CGRectGetWidth(rect)",
            "↓CGRectGetHeight(rect)",
            "↓CGRectGetMinX(rect)",
            "↓CGRectGetMidX(rect)",
            "↓CGRectGetMaxX(rect)",
            "↓CGRectGetMinY(rect)",
            "↓CGRectGetMidY(rect)",
            "↓CGRectGetMaxY(rect)",
            "↓CGRectIsNull(rect)",
            "↓CGRectIsEmpty(rect)",
            "↓CGRectIsInfinite(rect)",
            "↓CGRectStandardize(rect)",
            "↓CGRectIntegral(rect)",
            "↓CGRectInset(rect, 10, 5)",
            "↓CGRectOffset(rect, -2, 8.3)",
            "↓CGRectUnion(rect1, rect2)",
            "↓CGRectIntersection(rect1, rect2)",
            "↓CGRectContainsRect(rect1, rect2)",
            "↓CGRectContainsPoint(rect, point)",
            "↓CGRectIntersectsRect(rect1, rect2)",
        ]),
        corrections: #corrections([
            "↓CGRectGetWidth( rect  )": "rect.width",
            "↓CGRectGetHeight(rect )": "rect.height",
            "↓CGRectGetMinX( rect)": "rect.minX",
            "↓CGRectGetMidX(  rect)": "rect.midX",
            "↓CGRectGetMaxX( rect)": "rect.maxX",
            "↓CGRectGetMinY(rect   )": "rect.minY",
            "↓CGRectGetMidY(rect )": "rect.midY",
            "↓CGRectGetMaxY( rect     )": "rect.maxY",
            "↓CGRectIsNull(  rect    )": "rect.isNull",
            "↓CGRectIsEmpty( rect )": "rect.isEmpty",
            "↓CGRectIsInfinite( rect )": "rect.isInfinite",
            "↓CGRectStandardize( rect)": "rect.standardized",
            "↓CGRectIntegral(rect )": "rect.integral",
            "↓CGRectInset(rect, 5.0, -7.0)": "rect.insetBy(dx: 5.0, dy: -7.0)",
            "↓CGRectOffset(rect, -2, 8.3)": "rect.offsetBy(dx: -2, dy: 8.3)",
            "↓CGRectUnion(rect1, rect2)": "rect1.union(rect2)",
            "↓CGRectIntersection( rect1 ,rect2)": "rect1.intersection(rect2)",
            "↓CGRectContainsRect( rect1,rect2     )": "rect1.contains(rect2)",
            "↓CGRectContainsPoint(rect  ,point)": "rect.contains(point)",
            "↓CGRectIntersectsRect(  rect1,rect2 )": "rect1.intersects(rect2)",
            "↓CGRectIntersectsRect(rect1, rect2 )\n↓CGRectGetWidth(rect  )":
                "rect1.intersects(rect2)\nrect.width",
        ])
    )

    private static let legacyFunctions: [String: LegacyFunctionRewriteStrategy] = [
        "CGRectGetWidth": .property(name: "width"),
        "CGRectGetHeight": .property(name: "height"),
        "CGRectGetMinX": .property(name: "minX"),
        "CGRectGetMidX": .property(name: "midX"),
        "CGRectGetMaxX": .property(name: "maxX"),
        "CGRectGetMinY": .property(name: "minY"),
        "CGRectGetMidY": .property(name: "midY"),
        "CGRectGetMaxY": .property(name: "maxY"),
        "CGRectIsNull": .property(name: "isNull"),
        "CGRectIsEmpty": .property(name: "isEmpty"),
        "CGRectIsInfinite": .property(name: "isInfinite"),
        "CGRectStandardize": .property(name: "standardized"),
        "CGRectIntegral": .property(name: "integral"),
        "CGRectInset": .function(name: "insetBy", argumentLabels: ["dx", "dy"]),
        "CGRectOffset": .function(name: "offsetBy", argumentLabels: ["dx", "dy"]),
        "CGRectUnion": .function(name: "union", argumentLabels: [""]),
        "CGRectContainsRect": .function(name: "contains", argumentLabels: [""]),
        "CGRectContainsPoint": .function(name: "contains", argumentLabels: [""]),
        "CGRectIntersectsRect": .function(name: "intersects", argumentLabels: [""]),
        "CGRectIntersection": .function(name: "intersection", argumentLabels: [""]),
    ]
}

private extension LegacyCGGeometryFunctionsRule {
    final class Visitor: LegacyFunctionVisitor<ConfigurationType> {
        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file, legacyFunctions: legacyFunctions)
        }
    }

    final class Rewriter: LegacyFunctionRewriter<ConfigurationType> {
        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file, legacyFunctions: legacyFunctions)
        }
    }
}
