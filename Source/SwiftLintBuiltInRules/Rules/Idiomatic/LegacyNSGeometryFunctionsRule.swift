struct LegacyNSGeometryFunctionsRule: SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
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
            Example("rect1.intersection(rect2)"),
            // "rect.divide(atDistance: 10.2, fromEdge: edge)", No correction available for divide
            Example("rect1.contains(rect2)"),
            Example("rect.contains(point)"),
            Example("rect1.intersects(rect2)"),
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
            Example("↓NSIntersectsRect(rect1, rect2)"),
        ],
        corrections: [
            Example("↓NSWidth( rect  )"): Example("rect.width"),
            Example("↓NSHeight(rect )"): Example("rect.height"),
            Example("↓NSMinX( rect)"): Example("rect.minX"),
            Example("↓NSMidX(  rect)"): Example("rect.midX"),
            Example("↓NSMaxX( rect)"): Example("rect.maxX"),
            Example("↓NSMinY(rect   )"): Example("rect.minY"),
            Example("↓NSMidY(rect )"): Example("rect.midY"),
            Example("↓NSMaxY( rect     )"): Example("rect.maxY"),
            Example("↓NSEqualPoints( point1 , point2)"): Example("point1 == point2"),
            Example("↓NSEqualSizes(size1,size2   )"): Example("size1 == size2"),
            Example("↓NSEqualRects(  rect1,  rect2)"): Example("rect1 == rect2"),
            Example("↓NSEdgeInsetsEqual(insets1, insets2)"): Example("insets1 == insets2"),
            Example("↓NSIsEmptyRect( rect )"): Example("rect.isEmpty"),
            Example("↓NSIntegralRect(rect )"): Example("rect.integral"),
            Example("↓NSInsetRect(rect, 5.0, -7.0)"): Example("rect.insetBy(dx: 5.0, dy: -7.0)"),
            Example("↓NSOffsetRect(rect, -2, 8.3)"): Example("rect.offsetBy(dx: -2, dy: 8.3)"),
            Example("↓NSUnionRect(rect1, rect2)"): Example("rect1.union(rect2)"),
            Example("↓NSContainsRect( rect1,rect2     )"): Example("rect1.contains(rect2)"),
            Example("↓NSPointInRect(point  ,rect)"): Example("rect.contains(point)"), // note order of arguments
            Example("↓NSIntersectsRect(  rect1,rect2 )"): Example("rect1.intersects(rect2)"),
            Example("↓NSIntersectsRect(rect1, rect2 )\n↓NSWidth(rect  )"):
                Example("rect1.intersects(rect2)\nrect.width"),
            Example("↓NSIntersectionRect(rect1, rect2)"): Example("rect1.intersection(rect2)"),
        ]
    )

    private static let legacyFunctions: [String: LegacyFunctionRuleHelper.RewriteStrategy] = [
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        LegacyFunctionRuleHelper.Visitor(
            configuration: configuration,
            file: file,
            legacyFunctions: Self.legacyFunctions
        )
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter<ConfigurationType>? {
        LegacyFunctionRuleHelper.Rewriter(
            legacyFunctions: Self.legacyFunctions,
            configuration: configuration,
            file: file
        )
    }
}
