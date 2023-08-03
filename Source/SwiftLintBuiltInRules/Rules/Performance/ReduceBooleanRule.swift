import SwiftSyntax

struct ReduceBooleanRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`.",
        kind: .performance,
        nonTriggeringExamples: [
            "nums.reduce(0) { $0.0 + $0.1 }",
            "nums.reduce(0.0) { $0.0 + $0.1 }",
            "nums.reduce(initial: true) { $0.0 && $0.1 == 3 }"
        ],
        triggeringExamples: [
            "let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }",
            "let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }",
            "let allValid = validators.↓reduce(true) { $0 && $1(input) }",
            "let anyValid = validators.↓reduce(false) { $0 || $1(input) }",
            "let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })",
            "let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })",
            "let allValid = validators.↓reduce(true, { $0 && $1(input) })",
            "let anyValid = validators.↓reduce(false, { $0 || $1(input) })",
            "nums.reduce(into: true) { (r: inout Bool, s) in r = r && (s == 3) }"
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
                firstArgument.label?.text ?? "into" == "into",
                let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
            else {
                return
            }

            let suggestedFunction = bool.booleanLiteral.tokenKind == .keyword(.true) ? "allSatisfy" : "contains"
            violations.append(
                ReasonedRuleViolation(
                    position: calledExpression.name.positionAfterSkippingLeadingTrivia,
                    reason: "Use `\(suggestedFunction)` instead"
                )
            )
        }
    }
}
