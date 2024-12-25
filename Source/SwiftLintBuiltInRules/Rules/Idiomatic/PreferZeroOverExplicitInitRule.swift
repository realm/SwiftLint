import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct PreferZeroOverExplicitInitRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            Example("UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)"),
        ],
        triggeringExamples: [
            Example("↓CGPoint(x: 0, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0.000)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"),
            Example("↓CGSize(width: 0, height: 0)"),
            Example("↓CGVector(dx: 0, dy: 0)"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"),
        ],
        corrections: [
            Example("↓CGPoint(x: 0, y: 0)"): Example("CGPoint.zero"),
            Example("(↓CGPoint(x: 0, y: 0))"): Example("(CGPoint.zero)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"): Example("CGRect.zero"),
            Example("↓CGSize(width: 0, height: 0.000)"): Example("CGSize.zero"),
            Example("↓CGVector(dx: 0, dy: 0)"): Example("CGVector.zero"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"): Example("UIEdgeInsets.zero"),
        ]
    )
}

private extension PreferZeroOverExplicitInitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.hasViolation, let name = node.name else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let newNode = MemberAccessExprSyntax(name: "zero")
                .with(\.base, "\(raw: name)")
            return super.visit(
                newNode
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
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
        name == "CGPoint" &&
            argumentNames == ["x", "y"] &&
            argumentsAreAllZero
    }

    var isCGSizeCall: Bool {
        name == "CGSize" &&
            argumentNames == ["width", "height"] &&
            argumentsAreAllZero
    }

    var isCGRectCall: Bool {
        name == "CGRect" &&
            argumentNames == ["x", "y", "width", "height"] &&
            argumentsAreAllZero
    }

    var isCGVectorCall: Bool {
        name == "CGVector" &&
            argumentNames == ["dx", "dy"] &&
            argumentsAreAllZero
    }

    var isUIEdgeInsetsCall: Bool {
        name == "UIEdgeInsets" &&
            argumentNames == ["top", "left", "bottom", "right"] &&
            argumentsAreAllZero
    }

    var name: String? {
        guard let expr = calledExpression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }

        return expr.baseName.text
    }

    var argumentNames: [String?] {
        arguments.map(\.label?.text)
    }

    var argumentsAreAllZero: Bool {
        arguments.allSatisfy { arg in
            if let intExpr = arg.expression.as(IntegerLiteralExprSyntax.self) {
                return intExpr.isZero
            }
            if let floatExpr = arg.expression.as(FloatLiteralExprSyntax.self) {
                return floatExpr.isZero
            }
            return false
        }
    }
}
