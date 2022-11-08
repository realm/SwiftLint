struct LegacyNSGeometryFunctionsRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            Example("↓NSContainsRect( rect1,rect2     )\n"): Example("rect1.contains(rect2)\n"),
            Example("↓NSPointInRect(point  ,rect)\n"): Example("rect.contains(point)\n"), // note order of arguments
            Example("↓NSIntersectsRect(  rect1,rect2 )\n"): Example("rect1.intersects(rect2)\n"),
            Example("↓NSIntersectsRect(rect1, rect2 )\n↓NSWidth(rect  )\n"):
                Example("rect1.intersects(rect2)\nrect.width\n"),
            Example("↓NSIntersectionRect(rect1, rect2)"): Example("rect1.intersection(rect2)")
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
        "NSPointInRect": .function(name: "contains", argumentLabels: [""], reversed: true)
    ]

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        LegacyFunctionRuleHelper.Visitor(legacyFunctions: Self.legacyFunctions)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        LegacyFunctionRuleHelper.Rewriter(
            legacyFunctions: Self.legacyFunctions,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}
