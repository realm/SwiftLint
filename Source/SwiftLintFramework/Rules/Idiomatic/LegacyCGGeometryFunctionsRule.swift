import SwiftSyntax
import SwiftSyntaxBuilder

public struct LegacyCGGeometryFunctionsRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
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

private extension LegacyCGGeometryFunctionsRule {
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
        "CGRectIntersection": .function(name: "intersect", argumentLabels: [""])
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
            let rewriteStrategy = LegacyCGGeometryFunctionsRule.legacyFunctions[funcName]

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
            let rewriteStrategy = LegacyCGGeometryFunctionsRule.legacyFunctions[funcName],
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
