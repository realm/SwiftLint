import SwiftSyntax

struct YodaConditionRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "yoda_condition",
        name: "Yoda Condition",
        description: "The constant literal should be placed on the right-hand side of the comparison operator",
        kind: .lint,
        nonTriggeringExamples: [
            Example("if foo == 42 {}\n"),
            Example("if foo <= 42.42 {}\n"),
            Example("guard foo >= 42 else { return }\n"),
            Example("guard foo != \"str str\" else { return }"),
            Example("while foo < 10 { }\n"),
            Example("while foo > 1 { }\n"),
            Example("while foo + 1 == 2 {}"),
            Example("if optionalValue?.property ?? 0 == 2 {}"),
            Example("if foo == nil {}"),
            Example("if flags & 1 == 1 {}"),
            Example("if true {}", excludeFromDocumentation: true),
            Example("if true == false || b, 2 != 3, {}", excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("if ↓42 == foo {}\n"),
            Example("if ↓42.42 >= foo {}\n"),
            Example("guard ↓42 <= foo else { return }\n"),
            Example("guard ↓\"str str\" != foo else { return }"),
            Example("while ↓10 > foo { }"),
            Example("while ↓1 < foo { }"),
            Example("if ↓nil == foo {}"),
            Example("while ↓1 > i + 5 {}"),
            Example("if ↓200 <= i && i <= 299 || ↓600 <= i {}")
        ])

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        YodaConditionRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class YodaConditionRuleVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: IfExprSyntax) {
        visit(conditions: node.conditions)
    }

    override func visitPost(_ node: GuardStmtSyntax) {
        visit(conditions: node.conditions)
    }

    override func visitPost(_ node: RepeatWhileStmtSyntax) {
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
        guard let children = condition.as(SequenceExprSyntax.self)?.elements.children(viewMode: .sourceAccurate) else {
            return
        }
        let comparisonOperators = children
            .compactMap { $0.as(BinaryOperatorExprSyntax.self) }
            .filter { ["==", "!=", ">", "<", ">=", "<="].contains($0.operatorToken.text) }
        for comparisonOperator in comparisonOperators {
            let rhsIdx = children.index(after: comparisonOperator.index)
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
            let lhsIdx = children.index(before: comparisonOperator.index)
            let lhs = children[lhsIdx]
            if lhs.isLiteral {
                if children.startIndex == lhsIdx || children[children.index(before: lhsIdx)].isLogicalBinaryOperator {
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
        return ["&&", "||"].contains(binaryOperator.operatorToken.text)
    }
}
