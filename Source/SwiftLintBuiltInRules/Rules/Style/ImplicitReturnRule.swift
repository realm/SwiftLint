import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct ImplicitReturnRule: Rule {
    var configuration = ImplicitReturnConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
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
                collectViolation(in: node.statements)
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

        private func collectViolation(in itemList: CodeBlockItemListSyntax) {
            guard let onlyItem = itemList.onlyElement else {
                return
            }

            // Case 1: Direct return statement
            if let returnStmt = onlyItem.item.as(ReturnStmtSyntax.self) {
                addViolation(for: returnStmt)
                return
            }

            // Case 2: Expression statement containing if or switch
            if let exprStmt = onlyItem.item.as(ExpressionStmtSyntax.self) {
                analyzeExpressionForImplicitReturns(exprStmt.expression)
            }
        }

        private func analyzeExpressionForImplicitReturns(_ expr: ExprSyntax) {
            if let ifExpr = expr.as(IfExprSyntax.self) {
                analyzeIfExpression(ifExpr)
            } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
                analyzeSwitchExpression(switchExpr)
            }
        }

        private func analyzeIfExpression(_ ifExpr: IfExprSyntax) {
            guard checkIfAllBranchesCanUseImplicitReturn(ifExpr) else { return }

            let returnStatements = extractAllReturnStatements(from: ifExpr)
            returnStatements.forEach { addViolation(for: $0) }
        }

        private func analyzeSwitchExpression(_ switchExpr: SwitchExprSyntax) {
            guard checkIfAllCasesCanUseImplicitReturn(switchExpr) else { return }

            let returnStatements = extractAllReturnStatements(from: switchExpr)
            returnStatements.forEach { addViolation(for: $0) }
        }

        private func extractAllReturnStatements(from ifExpr: IfExprSyntax) -> [ReturnStmtSyntax] {
            var statements: [ReturnStmtSyntax] = []

            // Extract from main if body
            if let returnStmt = getSingleReturnStatement(from: ifExpr.body.statements) {
                statements.append(returnStmt)
            }

            // Extract from else body (recursively handle nested if-else)
            if let elseBody = ifExpr.elseBody {
                switch elseBody {
                case .codeBlock(let codeBlock):
                    if let returnStmt = getSingleReturnStatement(from: codeBlock.statements) {
                        statements.append(returnStmt)
                    }
                case .ifExpr(let nestedIfExpr):
                    statements.append(contentsOf: extractAllReturnStatements(from: nestedIfExpr))
                }
            }

            return statements
        }

        private func extractAllReturnStatements(from switchExpr: SwitchExprSyntax) -> [ReturnStmtSyntax] {
            switchExpr.cases.compactMap { caseItem in
                guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return nil }
                return getSingleReturnStatement(from: switchCase.statements)
            }
        }

        private func checkIfAllBranchesCanUseImplicitReturn(_ ifExpr: IfExprSyntax) -> Bool {
            guard isSingleReturnStatement(ifExpr.body.statements),
                  let elseBody = ifExpr.elseBody else {
                return false
            }

            switch elseBody {
            case .codeBlock(let codeBlock):
                return isSingleReturnStatement(codeBlock.statements)
            case .ifExpr(let nestedIfExpr):
                return checkIfAllBranchesCanUseImplicitReturn(nestedIfExpr)
            }
        }

        private func checkIfAllCasesCanUseImplicitReturn(_ switchExpr: SwitchExprSyntax) -> Bool {
            !switchExpr.cases.isEmpty &&
            switchExpr.cases.allSatisfy { caseItem in
                guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return false }
                return isSingleReturnStatement(switchCase.statements)
            }
        }

        private func isSingleReturnStatement(_ statements: CodeBlockItemListSyntax) -> Bool {
            getSingleReturnStatement(from: statements) != nil
        }

        private func getSingleReturnStatement(from statements: CodeBlockItemListSyntax) -> ReturnStmtSyntax? {
            statements.onlyElement?.item.as(ReturnStmtSyntax.self)
        }

        private func addViolation(for returnStmt: ReturnStmtSyntax) {
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
