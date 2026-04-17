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
        nonTriggeringExamples: [
            Example("if condition {}"),
            Example("if (a, b) == (0, 1) {}"),
            Example("if (a || b) && (c || d) {}"),
            Example("if (min...max).contains(value) {}"),
            Example("if renderGif(data) {}"),
            Example("renderGif(data)"),
            Example("guard condition else {}"),
            Example("while condition {}"),
            Example("do {} while condition {}"),
            Example("do { ; } while condition {}"),
            Example("switch foo {}"),
            Example("do {} catch let error as NSError {}"),
            Example("foo().catch(all: true) {}"),
            Example("if max(a, b) < c {}"),
            Example("switch (lhs, rhs) {}"),
            Example("if (f() { g() {} }) {}"),
            Example("if (a + f() {} == 1) {}"),
            Example("if ({ true }()) {}"),
            Example("if ({if i < 1 { true } else { false }}()) {}", excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("↓if (condition) {}"),
            Example("↓if(condition) {}"),
            Example("↓if (condition == endIndex) {}"),
            Example("↓if ((a || b) && (c || d)) {}"),
            Example("↓if ((min...max).contains(value)) {}"),
            Example("↓guard (condition) else {}"),
            Example("↓while (condition) {}"),
            Example("↓while(condition) {}"),
            Example("do { ; } ↓while(condition) {}"),
            Example("do { ; } ↓while (condition) {}"),
            Example("↓switch (foo) {}"),
            Example("do {} ↓catch(let error as NSError) {}"),
            Example("↓if (max(a, b) < c) {}"),
        ],
        corrections: [
            Example("↓if (condition) {}"): Example("if condition {}"),
            Example("↓if(condition) {}"): Example("if condition {}"),
            Example("↓if (condition == endIndex) {}"): Example("if condition == endIndex {}"),
            Example("↓if ((a || b) && (c || d)) {}"): Example("if (a || b) && (c || d) {}"),
            Example("↓if ((min...max).contains(value)) {}"): Example("if (min...max).contains(value) {}"),
            Example("↓guard (condition) else {}"): Example("guard condition else {}"),
            Example("↓while (condition) {}"): Example("while condition {}"),
            Example("↓while(condition) {}"): Example("while condition {}"),
            Example("do {} ↓while (condition) {}"): Example("do {} while condition {}"),
            Example("do {} ↓while(condition) {}"): Example("do {} while condition {}"),
            Example("do { ; } ↓while(condition) {}"): Example("do { ; } while condition {}"),
            Example("do { ; } ↓while (condition) {}"): Example("do { ; } while condition {}"),
            Example("↓switch (foo) {}"): Example("switch foo {}"),
            Example("do {} ↓catch(let error as NSError) {}"): Example("do {} catch let error as NSError {}"),
            Example("↓if (max(a, b) < c) {}"): Example("if max(a, b) < c {}"),
            Example("""
            ↓if (abc == 1/* && cdf == 2*/) {
                print("Hello, world!")
            }
            """): Example("""
                if abc == 1/* && cdf == 2*/ {
                    print("Hello, world!")
                }
                """),
            Example("""
            if (a),
               ( b == 1 ) {}
            """): Example("""
                if a,
                   b == 1 {}
                """),
        ]
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
            let node = node.with(\.body, super.visit(node.body))
            guard case let items = node.catchItems, items.containSuperfluousParens == true else {
                return node
            }
            numberOfCorrections += 1
            return node
                .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .space))
                .with(\.catchItems, items.withoutParens)
                .with(\.body, node.body.withLeftBraceLeadingTrivia(items.trailingCommentTrivia))
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            let node = node.with(\.body, super.visit(node.body))
            guard node.conditions.containSuperfluousParens else {
                return StmtSyntax(node)
            }
            numberOfCorrections += 1
            let elseKeyword = node.elseKeyword
                .with(\.leadingTrivia, node.conditions.trailingCommentTrivia + node.elseKeyword.leadingTrivia)
            return StmtSyntax(
                node
                    .with(\.guardKeyword, node.guardKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
                    .with(\.elseKeyword, elseKeyword)
            )
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            let node = node
                .with(\.body, super.visit(node.body))
                .with(\.elseBody, node.elseBody.map(rewriteElseBody))
            guard node.conditions.containSuperfluousParens else {
                return ExprSyntax(node)
            }
            numberOfCorrections += 1
            return ExprSyntax(
                node
                    .with(\.ifKeyword, node.ifKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
                    .with(\.body, node.body.withLeftBraceLeadingTrivia(node.conditions.trailingCommentTrivia))
            )
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            let node = node.with(\.cases, super.visit(node.cases))
            guard let tupleElement = node.subject.unwrapped else {
                return ExprSyntax(node)
            }
            numberOfCorrections += 1
            return ExprSyntax(
                node
                    .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                    .with(\.subject, tupleElement.with(\.trailingTrivia, tupleElement.trailingTrivia + .space))
            )
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            let node = node.with(\.body, super.visit(node.body))
            guard node.conditions.containSuperfluousParens else {
                return StmtSyntax(node)
            }
            numberOfCorrections += 1
            return StmtSyntax(
                node
                    .with(\.whileKeyword, node.whileKeyword.with(\.trailingTrivia, .space))
                    .with(\.conditions, node.conditions.withoutParens)
                    .with(\.body, node.body.withLeftBraceLeadingTrivia(node.conditions.trailingCommentTrivia))
            )
        }

        private func rewriteElseBody(_ elseBody: IfExprSyntax.ElseBody) -> IfExprSyntax.ElseBody {
            switch elseBody {
            case .ifExpr(let ifExpr):
                guard let rewritten = visit(ifExpr).as(IfExprSyntax.self) else {
                    return elseBody
                }
                return .ifExpr(rewritten)
            case .codeBlock(let codeBlock):
                return .codeBlock(super.visit(codeBlock))
            }
        }
    }
}

private extension ExprSyntax {
    var unwrapped: ExprSyntax? {
        if let tuple = `as`(TupleExprSyntax.self),
           let element = tuple.elements.onlyElement {
            var unwrapped = element.expression
            if containsTrailingClosure(Syntax(unwrapped)) {
                return nil
            }
            if tuple.leftParen.trailingTrivia.isNotEmpty {
                unwrapped = unwrapped.with(\.leadingTrivia, tuple.leftParen.trailingTrivia + unwrapped.leadingTrivia)
            }
            if tuple.rightParen.leadingTrivia.containsComments {
                unwrapped = unwrapped.with(\.trailingTrivia, unwrapped.trailingTrivia + tuple.rightParen.leadingTrivia)
            }
            return unwrapped
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
                let commentTrivia = expression.trailingTrivia.containsComments ? expression.trailingTrivia : []
                let trailingTrivia = if commentTrivia.isNotEmpty, element.trailingComma == nil {
                    Trivia()
                } else {
                    element.trailingTrivia
                }
                var updated = element
                    .with(\.condition, .expression(expression.with(\.trailingTrivia, [])))
                    .with(\.leadingTrivia, element.leadingTrivia)
                    .with(\.trailingTrivia, trailingTrivia)
                if let trailingComma = element.trailingComma, commentTrivia.isNotEmpty {
                    updated = updated.with(
                        \.trailingComma,
                        trailingComma.with(\.leadingTrivia, commentTrivia + trailingComma.leadingTrivia)
                    )
                }
                return updated
            }
            return element
        }
        return Self(conditions)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingCommentTrivia.isNotEmpty ? [] : trailingTrivia)
    }

    var trailingCommentTrivia: Trivia {
        guard let last,
              let expression = last.condition.as(ExprSyntax.self)?.unwrapped,
              expression.trailingTrivia.containsComments else {
            return []
        }
        return expression.trailingTrivia + last.trailingTrivia
    }
}

private extension CatchItemListSyntax {
    var containSuperfluousParens: Bool {
        contains { $0.unwrapped != nil }
    }

    var withoutParens: Self {
        let items = map { (item: CatchItemSyntax) -> CatchItemSyntax in
            if let expression = item.unwrapped {
                let commentTrivia = expression.trailingTrivia.containsComments ? expression.trailingTrivia : []
                let pattern = PatternSyntax(
                    ExpressionPatternSyntax(expression: expression.with(\.trailingTrivia, []))
                )
                return item
                    .with(\.pattern, pattern)
                    .with(\.leadingTrivia, item.leadingTrivia)
                    .with(\.trailingTrivia, commentTrivia + item.trailingTrivia)
            }
            return item
        }
        return Self(items)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingCommentTrivia.isNotEmpty ? [] : trailingTrivia)
    }

    var trailingCommentTrivia: Trivia {
        guard let last,
              let expression = last.unwrapped,
              expression.trailingTrivia.containsComments else {
            return []
        }
        return expression.trailingTrivia
    }
}

private extension CatchItemSyntax {
    var unwrapped: ExprSyntax? {
        pattern?.as(ExpressionPatternSyntax.self)?.expression.unwrapped
    }
}

private extension CodeBlockSyntax {
    func withLeftBraceLeadingTrivia(_ trivia: Trivia) -> Self {
        guard trivia.isNotEmpty else {
            return self
        }
        return with(\.leftBrace, leftBrace.with(\.leadingTrivia, trivia + leftBrace.leadingTrivia))
    }
}
