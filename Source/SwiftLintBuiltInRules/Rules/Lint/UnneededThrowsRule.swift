import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct UnneededThrowsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_throws_rethrows",
        name: "Unneeded (re)throws keyword",
        description: "Non-throwing functions/properties/closures should not be marked as `throws` or `rethrows`.",
        kind: .lint,
        nonTriggeringExamples: UnneededThrowsRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnneededThrowsRuleExamples.triggeringExamples,
        corrections: UnneededThrowsRuleExamples.corrections
    )
}

private extension UnneededThrowsRule {
    struct Scope {
        var throwsClause: ThrowsClauseSyntax?
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var scopes = Stack<Scope>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [
                ProtocolDeclSyntax.self,
                TypeAliasDeclSyntax.self,
                EnumCaseDeclSyntax.self,
            ]
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
                validate(
                    scope: closedScope,
                    reason: "initializer does not throw any error"
                )
            }
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: AccessorDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                validate(
                    scope: closedScope,
                    reason: "accessor does not throw any error"
                )
            }
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.signature.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_: FunctionDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                validate(
                    scope: closedScope,
                    reason: "body of this function does not throw any error"
                )
            }
        }

        override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
            if node.containsInitializerClause, let functionTypeSyntax = node.functionTypeSyntax {
                scopes.openScope(with: functionTypeSyntax.effectSpecifiers?.throwsClause)
            }
            return .visitChildren
        }

        override func visitPost(_: FunctionTypeSyntax) {
            if let closedScope = scopes.closeScope() {
                validate(
                    scope: closedScope,
                    reason: "closure type does not throw any error"
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

        override func visitPost(_ node: DoStmtSyntax) {
            if node.catchClauses.contains(where: { $0.catchItems.isEmpty }) {
                // All errors will be caught.
                return
            }
            scopes.markCurrentScopeAsThrowing()
        }

        override func visitPost(_ node: ForStmtSyntax) {
            if node.tryKeyword != nil {
                scopes.markCurrentScopeAsThrowing()
            }
        }

        override func visitPost(_ node: TryExprSyntax) {
            if node.questionOrExclamationMark == nil {
                scopes.markCurrentScopeAsThrowing()
            }
        }

        override func visitPost(_: ThrowStmtSyntax) {
            scopes.markCurrentScopeAsThrowing()
        }

        private func validate(scope: Scope, reason: String) {
            guard let throwsToken = scope.throwsClause?.throwsSpecifier else { return }
            violations.append(
                ReasonedRuleViolation(
                    position: throwsToken.positionAfterSkippingLeadingTrivia,
                    reason: "Superfluous 'throws'; " + reason,
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
            currentScope.throwsClause = nil
        }
    }

    mutating func openScope(with throwsClause: ThrowsClauseSyntax? = nil) {
        push(UnneededThrowsRule.Scope(throwsClause: throwsClause))
    }

    @discardableResult
    mutating func closeScope() -> Element? {
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

private extension PatternBindingSyntax {
    var containsInitializerClause: Bool {
        initializer != nil
    }

    var functionTypeSyntax: FunctionTypeSyntax? {
        guard let typeAnnotation else { return nil }

        var children = Set(typeAnnotation.children(viewMode: .sourceAccurate))

        while let child = children.popFirst() {
            if let functionType = child.as(FunctionTypeSyntax.self) {
                return functionType
            }
            children.formUnion(child.children(viewMode: .sourceAccurate))
        }

        return nil
    }
}
