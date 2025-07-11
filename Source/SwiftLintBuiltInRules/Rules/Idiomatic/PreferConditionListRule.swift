import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, optIn: true)
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
            Example("guard a ↓&& b ↓&& c else {}"),
            Example("if (a ↓&& b) {}"),
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
            Example("while a && b {}"):
                Example("while a, b {}"),
            Example("if a && b || c {}"):
                Example("if a && b || c {}"),
            Example("if (a && b) {}"):
                Example("if a, b {}"),
            Example("if a && (b && c) {}"):
                Example("if a, b, c {}"),
            Example("if (a && b) && c {}"):
                Example("if a, b, c {}"),
            Example("if (a && b), c {}"):
                Example("if a, b, c {}"),
            Example("guard (a || b) ↓&& c {}"):
                Example("guard a || b, c {}"),
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
            if let opExpr = expr.unwrap.as(InfixOperatorExprSyntax.self),
               let opToken = opExpr.operator.as(BinaryOperatorExprSyntax.self)?.operator,
               opToken.text == "&&" {
                violations.append(opToken.positionAfterSkippingLeadingTrivia)
                collectViolations(for: opExpr.leftOperand) // Expressions are left-recursive.
            }
        }
    }

    private final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
            var elements = Array(node)
            var index = 0

            while index < elements.count {
                let element = elements[index]
                guard case let .expression(expr) = element.condition else {
                    index += 1
                    continue
                }
                if let opExpr = expr.as(InfixOperatorExprSyntax.self),
                   let opToken = opExpr.operator.as(BinaryOperatorExprSyntax.self)?.operator,
                   opToken.text == "&&" {
                    numberOfCorrections += 1
                    elements[index] = ConditionElementSyntax(
                        condition: .expression(opExpr.leftOperand.with(\.trailingTrivia, [])),
                        trailingComma: .commaToken(),
                        trailingTrivia: opToken.trailingTrivia
                    )
                    elements.insert(
                        ConditionElementSyntax(
                            condition: .expression(opExpr.rightOperand.with(\.trailingTrivia, [])),
                            trailingComma: index == elements.count - 1 ? nil : .commaToken(),
                            trailingTrivia: .space
                        ),
                        at: index + 1
                    )
                    // Don't increment the index to re-evaluate `elements[index]`.
                } else if expr.is(TupleExprSyntax.self) {
                    // Unwrap parenthesized expression and repeat the loop for the inner expression (i.e. without
                    // incrementing the index).
                    elements[index] = element.with(\.condition, .expression(expr.unwrap))
                } else {
                    index += 1
                }
            }

            return super.visit(ConditionElementListSyntax(elements))
        }
    }
}

private extension ExprSyntax {
    var unwrap: ExprSyntax {
        self.as(TupleExprSyntax.self)?.elements.onlyElement?.expression ?? self
    }
}
