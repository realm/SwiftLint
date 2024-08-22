import SwiftSyntax

@SwiftSyntaxRule
struct PreferScaledToFitAndScaledToFill: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_scaled_to_fit_and_scaled_to_fill",
        name: "Prefer `scaledToFit()` and `scaledToFill()`",
        description: "Prefer `scaledToFit()` to `aspectRatio(contentMode: .fit)` and `scaledToFill` to `aspectRatio(contentMode: .fill)`",
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
            Example("↓view.aspectRatio(contentMode: .fit)"),
            Example("↓view.aspectRatio(contentMode: .fill)"),
            Example("↓aspectRatio(contentMode: .fit)"),
            Example("↓aspectRatio(contentMode: .fill)"),
        ]
    )
}

private extension PreferNimbleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               expr.baseName.text.starts(with: "XCTAssert") {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
