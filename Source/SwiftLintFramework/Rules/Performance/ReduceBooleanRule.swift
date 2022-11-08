import SwiftSyntax

struct ReduceBooleanRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("nums.reduce(0) { $0.0 + $0.1 }"),
            Example("nums.reduce(0.0) { $0.0 + $0.1 }")
        ],
        triggeringExamples: [
            Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
            Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
            Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
            Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
            Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
            Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
            Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
            Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ReduceBooleanRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "reduce",
                let firstArgument = node.argumentList.first,
                let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
            else {
                return
            }

            let suggestedFunction = bool.booleanLiteral.tokenKind == .trueKeyword ? "allSatisfy" : "contains"
            violations.append(
                ReasonedRuleViolation(
                    position: calledExpression.name.positionAfterSkippingLeadingTrivia,
                    reason: "Use `\(suggestedFunction)` instead"
                )
            )
        }
    }
}
