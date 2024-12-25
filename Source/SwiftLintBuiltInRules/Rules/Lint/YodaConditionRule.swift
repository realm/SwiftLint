import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct YodaConditionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "yoda_condition",
        name: "Yoda Condition",
        description: "The constant literal should be placed on the right-hand side of the comparison operator",
        kind: .lint,
        nonTriggeringExamples: [
            Example("if foo == 42 {}"),
            Example("if foo <= 42.42 {}"),
            Example("guard foo >= 42 else { return }"),
            Example("guard foo != \"str str\" else { return }"),
            Example("while foo < 10 { }"),
            Example("while foo > 1 { }"),
            Example("while foo + 1 == 2 {}"),
            Example("if optionalValue?.property ?? 0 == 2 {}"),
            Example("if foo == nil {}"),
            Example("if flags & 1 == 1 {}"),
            Example("if true {}", excludeFromDocumentation: true),
            Example("if true == false || b, 2 != 3, {}", excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("if ↓42 == foo {}"),
            Example("if ↓42.42 >= foo {}"),
            Example("guard ↓42 <= foo else { return }"),
            Example("guard ↓\"str str\" != foo else { return }"),
            Example("while ↓10 > foo { }"),
            Example("while ↓1 < foo { }"),
            Example("if ↓nil == foo {}"),
            Example("while ↓1 > i + 5 {}"),
            Example("if ↓200 <= i && i <= 299 || ↓600 <= i {}"),
        ])
}

private extension YodaConditionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            visit(conditions: node.conditions)
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            visit(conditions: node.conditions)
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            visit(condition: node.condition)
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            visit(conditions: node.conditions)
        }

        private func visit(conditions: ConditionElementListSyntax) {
            for condition in conditions.compactMap({ $0.condition.as(ExprSyntax.self) }) {
                visit(condition: condition)
            }
        }

        private func visit(condition: ExprSyntax) {
            guard let elements = condition.as(SequenceExprSyntax.self)?.elements else {
                return
            }
            let children = elements.children(viewMode: .sourceAccurate)
            let comparisonOperators = children
                .compactMap { $0.as(BinaryOperatorExprSyntax.self) }
                .filter { ["==", "!=", ">", "<", ">=", "<="].contains($0.operator.text) }
            for comparisonOperator in comparisonOperators {
                guard let operatorIndex = children.index(of: comparisonOperator) else {
                    continue
                }
                let rhsIdx = children.index(operatorIndex, offsetBy: 1)
                if children[rhsIdx].isLiteral {
                    let afterRhsIndex = children.index(after: rhsIdx)
                    guard children.endIndex != rhsIdx, afterRhsIndex != nil else {
                        // This is already the end of the expression.
                        continue
                    }
                    if children[afterRhsIndex].isLogicalBinaryOperator {
                        // Next token is an operator with weaker binding. Thus, the literal is unique on the
                        // right-hand side of the comparison operator.
                        continue
                    }
                }
                let lhsIdx = children.index(operatorIndex, offsetBy: -1)
                let lhs = children[lhsIdx]
                if lhs.isLiteral,
                   children.startIndex == lhsIdx || children[children.index(before: lhsIdx)].isLogicalBinaryOperator {
                        // Literal is at the very beginning of the expression or the previous token is an operator with
                        // weaker binding. Thus, the literal is unique on the left-hand side of the comparison operator.
                        violations.append(lhs.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private extension Syntax {
    var isLiteral: Bool {
           `is`(IntegerLiteralExprSyntax.self)
        || `is`(FloatLiteralExprSyntax.self)
        || `is`(BooleanLiteralExprSyntax.self)
        || `is`(StringLiteralExprSyntax.self)
        || `is`(NilLiteralExprSyntax.self)
    }

    var isLogicalBinaryOperator: Bool {
        guard let binaryOperator = `as`(BinaryOperatorExprSyntax.self) else {
            return false
        }
        return ["&&", "||"].contains(binaryOperator.operator.text)
    }
}
