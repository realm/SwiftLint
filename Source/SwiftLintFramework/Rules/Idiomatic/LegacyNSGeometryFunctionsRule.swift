import SwiftSyntax
import SwiftSyntaxBuilder

public struct LegacyNSGeometryFunctionsRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension LegacyNSGeometryFunctionsRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.isLegacyNSGeometryExpression {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    enum RewriteStrategy {
        case equal
        case property(name: String)
        case function(name: String, argumentLabels: [String], reversed: Bool = false)

        var expectedInitialArguments: Int {
            switch self {
            case .equal:
                return 2
            case .property:
                return 1
            case .function(name: _, argumentLabels: let argumentLabels, reversed: _):
                return argumentLabels.count + 1
            }
        }
    }

    static let legacyFunctions: [String: RewriteStrategy] = [
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

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                node.isLegacyNSGeometryExpression,
                let funcName = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let trimmedArguments = node.argumentList.map { $0.trimmed() }
            let rewriteStrategy = LegacyNSGeometryFunctionsRule.legacyFunctions[funcName]

            let expr: ExprSyntax
            switch rewriteStrategy {
            case .equal:
                expr = "\(trimmedArguments[0]) == \(trimmedArguments[1])"
            case let .property(name: propertyName):
                expr = "\(trimmedArguments[0]).\(propertyName)"
            case let .function(name: functionName, argumentLabels: argumentLabels, reversed: reversed):
                let arguments = reversed ? trimmedArguments.reversed() : trimmedArguments
                let params = zip(argumentLabels, arguments.dropFirst())
                    .map { $0.isEmpty ? "\($1)" : "\($0): \($1)" }
                    .joined(separator: ", ")
                expr = "\(arguments[0]).\(functionName)(\(params))"
            case .none:
                return super.visit(node)
            }

            return expr
                .withLeadingTrivia(node.leadingTrivia ?? .zero)
                .withTrailingTrivia(node.trailingTrivia ?? .zero)
        }

        private func isInDisabledRegion<T: SyntaxProtocol>(_ node: T) -> Bool {
            disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var isLegacyNSGeometryExpression: Bool {
        guard
            let calledExpression = calledExpression.as(IdentifierExprSyntax.self),
            case let funcName = calledExpression.identifier.text,
            let rewriteStrategy = LegacyNSGeometryFunctionsRule.legacyFunctions[funcName],
            argumentList.count == rewriteStrategy.expectedInitialArguments
        else {
            return false
        }

        return true
    }
}

private extension TupleExprElementSyntax {
    func trimmed() -> TupleExprElementSyntax {
        self
            .withoutTrivia()
            .withTrailingComma(nil)
            .withoutTrivia()
    }
}
