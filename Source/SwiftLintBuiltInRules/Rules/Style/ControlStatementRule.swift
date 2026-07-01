import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ControlStatementRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description:
            "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their " +
            "conditionals or arguments in parentheses",
        kind: .style,
        nonTriggeringExamples: #examples([
            "if condition {}",
            "if (a, b) == (0, 1) {}",
            "if (a || b) && (c || d) {}",
            "if (min...max).contains(value) {}",
            "if renderGif(data) {}",
            "renderGif(data)",
            "guard condition else {}",
            "while condition {}",
            "do {} while condition {}",
            "do { ; } while condition {}",
            "switch foo {}",
            "do {} catch let error as NSError {}",
            "foo().catch(all: true) {}",
            "if max(a, b) < c {}",
            "switch (lhs, rhs) {}",
            "if (f() { g() {} }) {}",
            "if (a + f() {} == 1) {}",
            "if ({ true }()) {}",
            "if ({if i < 1 { true } else { false }}()) {}".excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "↓if (condition) {}",
            "↓if(condition) {}",
            "↓if (condition == endIndex) {}",
            "↓if ((a || b) && (c || d)) {}",
            "↓if ((min...max).contains(value)) {}",
            "↓guard (condition) else {}",
            "↓while (condition) {}",
            "↓while(condition) {}",
            "do { ; } ↓while(condition) {}",
            "do { ; } ↓while (condition) {}",
            "↓switch (foo) {}",
            "do {} ↓catch(let error as NSError) {}",
            "↓if (max(a, b) < c) {}",
        ]),
        corrections: #corrections([
            "↓if (condition) {}": "if condition {}",
            "↓if(condition) {}": "if condition {}",
            "↓if (condition == endIndex) {}": "if condition == endIndex {}",
            "↓if ((a || b) && (c || d)) {}": "if (a || b) && (c || d) {}",
            "↓if ((min...max).contains(value)) {}": "if (min...max).contains(value) {}",
            "↓guard (condition) else {}": "guard condition else {}",
            "↓while (condition) {}": "while condition {}",
            "↓while(condition) {}": "while condition {}",
            "do {} ↓while (condition) {}": "do {} while condition {}",
            "do {} ↓while(condition) {}": "do {} while condition {}",
            "do { ; } ↓while(condition) {}": "do { ; } while condition {}",
            "do { ; } ↓while (condition) {}": "do { ; } while condition {}",
            "↓switch (foo) {}": "switch foo {}",
            "do {} ↓catch(let error as NSError) {}": "do {} catch let error as NSError {}",
            "↓if (max(a, b) < c) {}": "if max(a, b) < c {}",
            """
            if (a),
               ( b == 1 ) {}
            """: """
                if a,
                   b == 1 {}
                """,
        ])
    )
}

private extension ControlStatementRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: CatchClauseSyntax) {
            if node.catchItems.containSuperfluousParens == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if node.subject.unwrapped != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            guard case let items = node.catchItems, items.containSuperfluousParens == true else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node = node
                .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .space))
                .with(\.catchItems, items.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node = node
                .with(\.guardKeyword, node.guardKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node = node
                .with(\.ifKeyword, node.ifKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard let tupleElement = node.subject.unwrapped else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node = node
                .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                .with(\.subject, tupleElement.with(\.trailingTrivia, .space))
            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            guard node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let node = node
                .with(\.whileKeyword, node.whileKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }
    }
}

private extension ExprSyntax {
    var unwrapped: ExprSyntax? {
        if let expr = `as`(TupleExprSyntax.self)?.elements.onlyElement?.expression {
            return containsTrailingClosure(Syntax(expr)) ? nil : expr
        }
        return nil
    }

    private func containsTrailingClosure(_ node: Syntax) -> Bool {
        switch node.as(SyntaxEnum.self) {
        case .functionCallExpr(let node):
            node.trailingClosure != nil || node.calledExpression.is(ClosureExprSyntax.self)
        case .sequenceExpr(let node):
            node.elements.contains { containsTrailingClosure(Syntax($0)) }
        default: false
        }
    }
}

private extension ConditionElementListSyntax {
    var containSuperfluousParens: Bool {
        contains {
            if case let .expression(wrapped) = $0.condition {
                return wrapped.unwrapped != nil
            }
            return false
        }
    }

    var withoutParens: Self {
        let conditions = map { (element: ConditionElementSyntax) -> ConditionElementSyntax in
            if let expression = element.condition.as(ExprSyntax.self)?.unwrapped {
                return element
                    .with(\.condition, .expression(expression))
                    .with(\.leadingTrivia, element.leadingTrivia)
                    .with(\.trailingTrivia, element.trailingTrivia)
            }
            return element
        }
        return Self(conditions)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

private extension CatchItemListSyntax {
    var containSuperfluousParens: Bool {
        contains { $0.unwrapped != nil }
    }

    var withoutParens: Self {
        let items = map { (item: CatchItemSyntax) -> CatchItemSyntax in
            if let expression = item.unwrapped {
                return item
                    .with(\.pattern, PatternSyntax(ExpressionPatternSyntax(expression: expression)))
                    .with(\.leadingTrivia, item.leadingTrivia)
                    .with(\.trailingTrivia, item.trailingTrivia)
            }
            return item
        }
        return Self(items)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

private extension CatchItemSyntax {
    var unwrapped: ExprSyntax? {
        pattern?.as(ExpressionPatternSyntax.self)?.expression.unwrapped
    }
}
