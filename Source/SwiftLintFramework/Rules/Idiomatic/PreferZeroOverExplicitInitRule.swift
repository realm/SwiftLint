import SwiftSyntax

struct PreferZeroOverExplicitInitRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "prefer_zero_over_explicit_init",
        name: "Prefer Zero Over Explicit Init",
        description: "Prefer `.zero` over explicit init with zero parameters (e.g. `CGPoint(x: 0, y: 0)`)",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("CGRect(x: 0, y: 0, width: 0, height: 1)"),
            Example("CGPoint(x: 0, y: -1)"),
            Example("CGSize(width: 2, height: 4)"),
            Example("CGVector(dx: -5, dy: 0)"),
            Example("UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)")
        ],
        triggeringExamples: [
            Example("↓CGPoint(x: 0, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0.000)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"),
            Example("↓CGSize(width: 0, height: 0)"),
            Example("↓CGVector(dx: 0, dy: 0)"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)")
        ],
        corrections: [
            Example("↓CGPoint(x: 0, y: 0)"): Example("CGPoint.zero"),
            Example("(↓CGPoint(x: 0, y: 0))"): Example("(CGPoint.zero)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"): Example("CGRect.zero"),
            Example("↓CGSize(width: 0, height: 0.000)"): Example("CGSize.zero"),
            Example("↓CGVector(dx: 0, dy: 0)"): Example("CGVector.zero"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"): Example("UIEdgeInsets.zero")
        ]
    )

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension PreferZeroOverExplicitInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.hasViolation,
                  let name = node.name,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let newNode = MemberAccessExprSyntax(name: "zero")
                .with(\.base, "\(raw: name)")
            return super.visit(
                newNode
                    .with(\.leadingTrivia, node.leadingTrivia ?? .zero)
                    .with(\.trailingTrivia, node.trailingTrivia ?? .zero)
            )
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasViolation: Bool {
        isCGPointZeroCall ||
            isCGSizeCall ||
            isCGRectCall ||
            isCGVectorCall ||
            isUIEdgeInsetsCall
    }

    var isCGPointZeroCall: Bool {
        return name == "CGPoint" &&
            argumentNames == ["x", "y"] &&
            argumentsAreAllZero
    }

    var isCGSizeCall: Bool {
        return name == "CGSize" &&
            argumentNames == ["width", "height"] &&
            argumentsAreAllZero
    }

    var isCGRectCall: Bool {
        return name == "CGRect" &&
            argumentNames == ["x", "y", "width", "height"] &&
            argumentsAreAllZero
    }

    var isCGVectorCall: Bool {
        return name == "CGVector" &&
            argumentNames == ["dx", "dy"] &&
            argumentsAreAllZero
    }

    var isUIEdgeInsetsCall: Bool {
        return name == "UIEdgeInsets" &&
            argumentNames == ["top", "left", "bottom", "right"] &&
            argumentsAreAllZero
    }

    var name: String? {
        guard let expr = calledExpression.as(IdentifierExprSyntax.self) else {
            return nil
        }

        return expr.identifier.text
    }

    var argumentNames: [String?] {
        argumentList.map(\.label?.text)
    }

    var argumentsAreAllZero: Bool {
        argumentList.allSatisfy { arg in
            if let intExpr = arg.expression.as(IntegerLiteralExprSyntax.self) {
                return intExpr.isZero
            } else if let floatExpr = arg.expression.as(FloatLiteralExprSyntax.self) {
                return floatExpr.isZero
            } else {
                return false
            }
        }
    }
}
