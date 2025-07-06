import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, correctable: true, optIn: true)
struct PreferConditionListRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_condition_list",
        name: "Prefer Condition List",
        description: "Prefer a condition list over chaining conditions with '&&'",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("if a, b {}"),
            Example("guard a || b && c {}"),
            Example("if a && b || c {}"),
            Example("let result = a && b"),
            Example("repeat {} while a && b"),
        ],
        triggeringExamples: [
            Example("if a ↓&& b {}"),
            Example("if a ↓&& b ↓&& c {}"),
            Example("while a ↓&& b {}"),
            Example("guard a ↓&& b {}"),
            Example("guard (a || b) ↓&& c {}"),
            Example("if a ↓&& (b && c) {}"),
        ],
        corrections: [
            Example("if a && b {}"):
                Example("if a, b {}"),
            Example("""
                if a &&
                   b {}
                """): Example("""
                if a,
                   b {}
                """),
            Example("guard a && b && c else {}"):
                Example("guard a, b, c else {}"),
        ]
    )
}

private extension PreferConditionListRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ConditionElementSyntax) {
            if case let .expression(expr) = node.condition {
                collectViolations(for: expr)
            }
        }

        private func collectViolations(for expr: ExprSyntax) {
            guard let opExpr = expr.as(InfixOperatorExprSyntax.self),
                  let opToken = opExpr.operator.as(BinaryOperatorExprSyntax.self)?.operator,
                  opToken.text == "&&" else {
                return
            }
            let opLine = locationConverter.location(for: opToken.positionAfterSkippingLeadingTrivia).line
            let rightOperandLine = locationConverter.location(
                for: opExpr.rightOperand.positionAfterSkippingLeadingTrivia
            ).line
            violations.append(
                .init(
                    position: opToken.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: opExpr.leftOperand.endPositionBeforeTrailingTrivia,
                        end: opToken.endPosition,
                        replacement: ",\(opLine == rightOperandLine ? " " : "")"
                    )
                )
            )
            collectViolations(for: opExpr.leftOperand)
        }
    }
}
