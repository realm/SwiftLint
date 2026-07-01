import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct PreferZeroOverExplicitInitRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_zero_over_explicit_init",
        name: "Prefer Zero Over Explicit Init",
        description: "Prefer `.zero` over explicit init with zero parameters (e.g. `CGPoint(x: 0, y: 0)`)",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "CGRect(x: 0, y: 0, width: 0, height: 1)",
            "CGPoint(x: 0, y: -1)",
            "CGSize(width: 2, height: 4)",
            "CGVector(dx: -5, dy: 0)",
            "UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)",
        ]),
        triggeringExamples: #examples([
            "↓CGPoint(x: 0, y: 0)",
            "↓CGPoint(x: 0.000000, y: 0)",
            "↓CGPoint(x: 0.000000, y: 0.000)",
            "↓CGRect(x: 0, y: 0, width: 0, height: 0)",
            "↓CGSize(width: 0, height: 0)",
            "↓CGVector(dx: 0, dy: 0)",
            "↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)",
        ]),
        corrections: #corrections([
            "↓CGPoint(x: 0, y: 0)": "CGPoint.zero",
            "(↓CGPoint(x: 0, y: 0))": "(CGPoint.zero)",
            "↓CGRect(x: 0, y: 0, width: 0, height: 0)": "CGRect.zero",
            "↓CGSize(width: 0, height: 0.000)": "CGSize.zero",
            "↓CGVector(dx: 0, dy: 0)": "CGVector.zero",
            "↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)": "UIEdgeInsets.zero",
        ])
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
            numberOfCorrections += 1
            let newNode = MemberAccessExprSyntax(name: "zero")
                .with(\.base, "\(raw: name)")
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
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
