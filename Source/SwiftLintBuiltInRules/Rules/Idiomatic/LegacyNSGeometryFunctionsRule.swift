import SwiftLintCore

@SwiftSyntaxRule(explicitRewriter: true)
struct LegacyNSGeometryFunctionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_nsgeometry_functions",
        name: "Legacy NSGeometry Functions",
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
            "rect.isEmpty",
            "rect.integral",
            "rect.insetBy(dx: 5.0, dy: -7.0)",
            "rect.offsetBy(dx: 5.0, dy: -7.0)",
            "rect1.union(rect2)",
            "rect1.intersection(rect2)",
            // "rect.divide(atDistance: 10.2, fromEdge: edge)", No correction available for divide
            "rect1.contains(rect2)",
            "rect.contains(point)",
            "rect1.intersects(rect2)",
        ]),
        triggeringExamples: #examples([
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
            "↓NSIntersectsRect(rect1, rect2)",
        ]),
        corrections: #corrections([
            "↓NSWidth( rect  )": "rect.width",
            "↓NSHeight(rect )": "rect.height",
            "↓NSMinX( rect)": "rect.minX",
            "↓NSMidX(  rect)": "rect.midX",
            "↓NSMaxX( rect)": "rect.maxX",
            "↓NSMinY(rect   )": "rect.minY",
            "↓NSMidY(rect )": "rect.midY",
            "↓NSMaxY( rect     )": "rect.maxY",
            "↓NSEqualPoints( point1 , point2)": "point1 == point2",
            "↓NSEqualSizes(size1,size2   )": "size1 == size2",
            "↓NSEqualRects(  rect1,  rect2)": "rect1 == rect2",
            "↓NSEdgeInsetsEqual(insets1, insets2)": "insets1 == insets2",
            "↓NSIsEmptyRect( rect )": "rect.isEmpty",
            "↓NSIntegralRect(rect )": "rect.integral",
            "↓NSInsetRect(rect, 5.0, -7.0)": "rect.insetBy(dx: 5.0, dy: -7.0)",
            "↓NSOffsetRect(rect, -2, 8.3)": "rect.offsetBy(dx: -2, dy: 8.3)",
            "↓NSUnionRect(rect1, rect2)": "rect1.union(rect2)",
            "↓NSContainsRect( rect1,rect2     )": "rect1.contains(rect2)",
            "↓NSPointInRect(point  ,rect)": "rect.contains(point)", // note order of arguments
            "↓NSIntersectsRect(  rect1,rect2 )": "rect1.intersects(rect2)",
            "↓NSIntersectsRect(rect1, rect2 )\n↓NSWidth(rect  )":
                "rect1.intersects(rect2)\nrect.width",
            "↓NSIntersectionRect(rect1, rect2)": "rect1.intersection(rect2)",
        ])
    )

    private static let legacyFunctions: [String: LegacyFunctionRewriteStrategy] = [
        "NSHeight": .property(name: "height"),
        "NSIntegralRect": .property(name: "integral"),
        "NSIsEmptyRect": .property(name: "isEmpty"),
        "NSMaxX": .property(name: "maxX"),
        "NSMaxY": .property(name: "maxY"),
        "NSMidX": .property(name: "midX"),
        "NSMidY": .property(name: "midY"),
        "NSMinX": .property(name: "minX"),
        "NSMinY": .property(name: "minY"),
        "NSWidth": .property(name: "width"),
        "NSEqualPoints": .equal,
        "NSEqualSizes": .equal,
        "NSEqualRects": .equal,
        "NSEdgeInsetsEqual": .equal,
        "NSInsetRect": .function(name: "insetBy", argumentLabels: ["dx", "dy"]),
        "NSOffsetRect": .function(name: "offsetBy", argumentLabels: ["dx", "dy"]),
        "NSUnionRect": .function(name: "union", argumentLabels: [""]),
        "NSContainsRect": .function(name: "contains", argumentLabels: [""]),
        "NSIntersectsRect": .function(name: "intersects", argumentLabels: [""]),
        "NSIntersectionRect": .function(name: "intersection", argumentLabels: [""]),
        "NSPointInRect": .function(name: "contains", argumentLabels: [""], reversed: true),
    ]
}

private extension LegacyNSGeometryFunctionsRule {
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
