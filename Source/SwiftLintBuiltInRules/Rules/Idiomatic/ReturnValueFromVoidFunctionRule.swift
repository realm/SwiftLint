import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ReturnValueFromVoidFunctionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "return_value_from_void_function",
        name: "Return Value from Void Function",
        description: "Returning values from Void functions should be avoided",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    )
}

private extension ReturnValueFromVoidFunctionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ReturnStmtSyntax) {
            if node.expression != nil,
               let functionNode = Syntax(node).enclosingFunction(),
               functionNode.returnsVoid {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            guard let returnStmt = statements.last?.item.as(ReturnStmtSyntax.self),
                  let expr = returnStmt.expression,
                  Syntax(statements).enclosingFunction()?.returnsVoid == true else {
                return super.visit(statements)
            }
            correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)
            let newStmtList = Array(statements.dropLast()) + [
                CodeBlockItemSyntax(item: .expr(expr))
                    .with(\.leadingTrivia, returnStmt.leadingTrivia),
                CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                    returnStmt
                        .with(\.expression, nil)
                        .with(
                            \.leadingTrivia,
                            .newline + (returnStmt.leadingTrivia.indentation(isOnNewline: false) ?? []))
                        .with(\.trailingTrivia, returnStmt.trailingTrivia)
                ))),
            ]
            return super.visit(CodeBlockItemListSyntax(newStmtList))
        }
    }
}

private extension Syntax {
    func enclosingFunction() -> FunctionDeclSyntax? {
        if let node = self.as(FunctionDeclSyntax.self) {
            return node
        }

        if self.is(ClosureExprSyntax.self) || self.is(VariableDeclSyntax.self) || self.is(InitializerDeclSyntax.self) {
            return nil
        }

        return parent?.enclosingFunction()
    }
}

private extension FunctionDeclSyntax {
    var returnsVoid: Bool {
        guard let type = signature.returnClause?.type else {
            return true
        }
        return type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
            || type.as(TupleTypeSyntax.self)?.elements.isEmpty == true
    }
}
