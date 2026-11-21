import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct ImplicitReturnRule: Rule {
    var configuration = ImplicitReturnConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples
            + ImplicitReturnRuleExamples.IfAndSwitchExpressionExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples
            + ImplicitReturnRuleExamples.IfAndSwitchExpressionExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
            .merging(ImplicitReturnRuleExamples.IfAndSwitchExpressionExamples.corrections) { _, _ in
                preconditionFailure("Duplicate correction in implicit return rule examples.")
            }
    )
}

private extension ImplicitReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if configuration.isKindIncluded(.getter),
               node.accessorSpecifier.tokenKind == .keyword(.get),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if configuration.isKindIncluded(.closure) {
                // Without an explicit return type, the branches of an `if` or `switch` expression are type-checked
                // independently, which may fail where the `return` statements compiled fine (e.g. `1` and `nil`).
                collectViolation(
                    in: node.statements,
                    checkIfAndSwitch: node.signature?.returnClause != nil
                )
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if configuration.isKindIncluded(.function),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if configuration.isKindIncluded(.initializer),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if configuration.isKindIncluded(.getter),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if configuration.isKindIncluded(.subscript),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        private func collectViolation(in itemList: CodeBlockItemListSyntax, checkIfAndSwitch: Bool = true) {
            if let returnStmt = itemList.onlyReturnStatement {
                collectViolation(for: returnStmt)
            } else if checkIfAndSwitch, configuration.checkIfAndSwitchExpressions,
                      let returnStmts = itemList.ifOrSwitchExpressionReturnStatements {
                returnStmts.forEach(collectViolation(for:))
            }
        }

        private func collectViolation(for returnStmt: ReturnStmtSyntax) {
            let returnKeyword = returnStmt.returnKeyword
            violations.append(
                at: returnKeyword.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: returnKeyword.positionAfterSkippingLeadingTrivia,
                    end: returnKeyword.endPositionBeforeTrailingTrivia
                            .advanced(by: returnStmt.expression == nil ? 0 : 1),
                    replacement: ""
                )
            )
        }
    }
}

private extension CodeBlockItemListSyntax {
    var onlyReturnStatement: ReturnStmtSyntax? {
        onlyElement?.item.as(ReturnStmtSyntax.self)
    }

    /// The `return` statements in all branches of the only statement in this list if it is an `if` or `switch`
    /// that could be used as an expression after removing them. `nil` otherwise.
    var ifOrSwitchExpressionReturnStatements: [ReturnStmtSyntax]? {
        guard let expression = onlyElement?.item.as(ExpressionStmtSyntax.self)?.expression else {
            return nil
        }
        if let ifExpr = expression.as(IfExprSyntax.self) {
            return ifExpr.branchReturnStatements
        }
        if let switchExpr = expression.as(SwitchExprSyntax.self) {
            return switchExpr.branchReturnStatements
        }
        return nil
    }

    /// The `return` statements that make this branch of an `if` or `switch` produce a value. Either the branch's
    /// only statement returning a value or the returns of a nested `if` or `switch` qualifying itself.
    var branchReturnStatements: [ReturnStmtSyntax]? {
        if let returnStmt = onlyReturnStatement {
            return returnStmt.expression == nil ? nil : [returnStmt]
        }
        return ifOrSwitchExpressionReturnStatements
    }
}

private extension IfExprSyntax {
    var branchReturnStatements: [ReturnStmtSyntax]? {
        guard let thenReturns = body.statements.branchReturnStatements else {
            return nil
        }
        let elseReturns: [ReturnStmtSyntax]? = switch elseBody {
        case let .codeBlock(block): block.statements.branchReturnStatements
        case let .ifExpr(ifExpr): ifExpr.branchReturnStatements
        case nil: nil
        }
        return elseReturns.map { thenReturns + $0 }
    }
}

private extension SwitchExprSyntax {
    var branchReturnStatements: [ReturnStmtSyntax]? {
        var returns = [ReturnStmtSyntax]()
        for element in cases {
            guard case let .switchCase(switchCase) = element,
                  let caseReturns = switchCase.statements.branchReturnStatements else {
                return nil
            }
            returns += caseReturns
        }
        return returns.isEmpty ? nil : returns
    }
}
