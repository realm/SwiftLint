import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct PreferScaledToFitAndScaledToFill: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_scaled_to_fit_and_scaled_to_fill",
        name: "Prefer `scaledToFit()` and `scaledToFill()`",
        description: "Prefer `scaledToFit` and `scaledToFill` to `aspectRatio`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            let ratio = CGSize(width: 1, height: 1)
            view.aspectRatio(ratio, contentMode: .fit)
            view.aspectRatio(ratio, contentMode: .fill)
            """),
            Example("""
            let contentMode = ContentMode.fit
            view.aspectRatio(contentMode: contentMode)
            """),
            Example("""
            let shouldFit = true
            view.aspectRatio(contentMode: shouldFit ? .fit : .fill)
            """),
        ],
        triggeringExamples: [
            Example("view.↓aspectRatio(contentMode: .fit)"),
            Example("view.↓aspectRatio(contentMode: .fill)"),
            Example("↓aspectRatio(contentMode: .fit)"),
            Example("↓aspectRatio(contentMode: .fill)"),
        ],
        corrections: [
            Example("view.↓aspectRatio(contentMode: .fit)"): Example("view.scaledToFit()"),
            Example("view.↓aspectRatio(contentMode: .fill)"): Example("view.scaledToFill()"),
            Example("↓aspectRatio(contentMode: .fit)"): Example("scaledToFit()"),
            Example("↓aspectRatio(contentMode: .fill)"): Example("scaledToFill()"),
        ]
    )
}

private extension PreferScaledToFitAndScaledToFill {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            // if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
            //    expr.baseName.text.starts(with: "XCTAssert") {
            //     violations.append(node.positionAfterSkippingLeadingTrivia)
            // }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            if node.hasViolation {
                return ExprSyntax(stringLiteral: "A is C")
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
            }

            return ExprSyntax(stringLiteral: "A is B")
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasViolation: Bool {
        name == "aspectRatio"
        && argumentNames == ["contentMode"]
        && argumentIsFitOrFill
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

    var argumentIsFitOrFill: Bool {
        true
    }
}
