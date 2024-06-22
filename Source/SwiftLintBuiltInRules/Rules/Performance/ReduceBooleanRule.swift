import SwiftSyntax

@SwiftSyntaxRule
struct ReduceBooleanRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("nums.reduce(0) { $0.0 + $0.1 }"),
            Example("nums.reduce(0.0) { $0.0 + $0.1 }"),
            Example("nums.reduce(initial: true) { $0.0 && $0.1 == 3 }"),
        ],
        triggeringExamples: [
            Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
            Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
            Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
            Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
            Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
            Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
            Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
            Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })"),
            Example("nums.reduce(into: true) { (r: inout Bool, s) in r = r && (s == 3) }"),
        ]
    )
}

private extension ReduceBooleanRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.declName.baseName.text == "reduce",
                let firstArgument = node.arguments.first,
                firstArgument.label?.text ?? "into" == "into",
                let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
            else {
                return
            }

            let suggestedFunction = bool.literal.tokenKind == .keyword(.true) ? "allSatisfy" : "contains"
            violations.append(
                ReasonedRuleViolation(
                    position: calledExpression.declName.baseName.positionAfterSkippingLeadingTrivia,
                    reason: "Use `\(suggestedFunction)` instead"
                )
            )
        }
    }
}
