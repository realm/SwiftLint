import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct UnneededThrowsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_throws_rethrows",
        name: "Unneeded (re)throws keyword",
        description: "Non-throwing functions/variables should not me marked as `throws` or `rethrows`",
        kind: .lint,
        nonTriggeringExamples: UnneededThrowsRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnneededThrowsRuleExamples.triggeringExamples,
        corrections: UnneededThrowsRuleExamples.corrections
    )
}

private extension UnneededThrowsRule {
    typealias Scope = [ThrowsClauseSyntax]

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var scopes = Stack<Scope>()

        override func visit(_: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.signature.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: InitializerDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                validateScope(
                    closedScope,
                    reason: "The initializer does not throw any error"
                )
            }
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: AccessorDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                validateScope(
                    closedScope,
                    reason: "The accessor does not throw any error"
                )
            }
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.signature.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: FunctionDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                validateScope(
                    closedScope,
                    reason: "The body of this function does not throw any error"
                )
            }
        }

        override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: FunctionTypeSyntax) {
            if let closedScope = scopes.closeScope() {
                validateScope(
                    closedScope,
                    reason: "The closure type does not throw any error"
                )
            }
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if node.containsTaskDeclaration {
                scopes.openScope()
            }
            return .visitChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.containsTaskDeclaration {
                scopes.closeScope()
            }
        }

        override func visit(_: DoStmtSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope()
            return .visitChildren
        }

        override func visitPost(_ node: CodeBlockSyntax) {
            if node.parent?.is(DoStmtSyntax.self) == true {
                scopes.closeScope()
            }
        }

        override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            if node.tryKeyword != nil {
                scopes.markCurrentScopeAsThrowing()
            }
            return .visitChildren
        }

        override func visitPost(_ node: TryExprSyntax) {
            if node.questionOrExclamationMark == nil {
                scopes.markCurrentScopeAsThrowing()
            }
        }

        override func visitPost(_: ThrowStmtSyntax) {
            scopes.markCurrentScopeAsThrowing()
        }

        private func validateScope(_ scope: Scope, reason: String) {
            guard let throwsToken = scope.last?.throwsSpecifier else { return }
            violations.append(
                ReasonedRuleViolation(
                    position: throwsToken.positionAfterSkippingLeadingTrivia,
                    reason: reason,
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: throwsToken.positionAfterSkippingLeadingTrivia,
                        end: throwsToken.endPosition,
                        replacement: ""
                    )
                )
            )
        }
    }
}

private extension Stack where Element == UnneededThrowsRule.Scope {
    mutating func markCurrentScopeAsThrowing() {
        modifyLast { currentScope in
            _ = currentScope.popLast()
        }
    }

    mutating func openScope() {
        push([])
    }

    mutating func openScope(with throwsClause: ThrowsClauseSyntax?) {
        if let throwsClause {
            push([throwsClause])
        }
    }

    @discardableResult
    mutating func closeScope() -> [ThrowsClauseSyntax]? {
        pop()
    }
}

private extension FunctionCallExprSyntax {
    var containsTaskDeclaration: Bool {
        children(viewMode: .sourceAccurate).contains { child in
            child.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .identifier("Task")
        }
    }
}
