import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct UnneededThrowsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_throws_rethrows",
        name: "Unneeded (Re)Throws Keyword",
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
                    construct: "initializer"
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
                    construct: "accessor"
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
                    construct: "body of this function"
                )
            }
        }

        override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
            if node.hasNonReferenceInitializer, let functionTypeSyntax = node.functionTypeSyntax {
                scopes.openScope(with: functionTypeSyntax.effectSpecifiers?.throwsClause)
            }
            return .visitChildren
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if node.hasNonReferenceInitializer, node.functionTypeSyntax != nil {
                if let closedScope = scopes.closeScope() {
                    validate(
                        scope: closedScope,
                        construct: "closure type"
                    )
                }
            }
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if node.containsClosureDeclaration {
                scopes.openScope()
            }
            return .visitChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.containsClosureDeclaration {
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
            if node.catchClauses.contains(where: \.catchItems.isEmpty) {
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

        private func validate(scope: Scope, construct: String) {
            guard let throwsClause = scope.throwsClause else { return }
            violations.append(
                ReasonedRuleViolation(
                    position: throwsClause.positionAfterSkippingLeadingTrivia,
                    reason: "Superfluous 'throws'; \(construct) does not throw any error",
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        // Move start position back by 1 to include the space before the throwsClause
                        start: throwsClause.positionAfterSkippingLeadingTrivia.advanced(by: -1),
                        end: throwsClause.endPositionBeforeTrailingTrivia,
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
    var containsClosureDeclaration: Bool {
        children(viewMode: .sourceAccurate).contains { child in
            child.as(ClosureExprSyntax.self.self) != nil
        }
    }
}

private extension PatternBindingSyntax {
    var hasNonReferenceInitializer: Bool {
        children(viewMode: .sourceAccurate).contains { child in
            guard let initializer = child.as(InitializerClauseSyntax.self) else {
                return false
            }
            let containsDeclReference = initializer.children(viewMode: .sourceAccurate)
                .contains { $0.as(DeclReferenceExprSyntax.self) != nil }
            return !containsDeclReference
        }
    }

    var functionTypeSyntax: FunctionTypeSyntax? {
        typeAnnotation?.type.baseFunctionTypeSyntax
    }
}

private extension TypeSyntax {
    var baseFunctionTypeSyntax: FunctionTypeSyntax? {
        switch Syntax(self).as(SyntaxEnum.self) {
        case .functionType(let function):
            function
        case .optionalType(let optional):
            optional.wrappedType.baseFunctionTypeSyntax
        case .attributedType(let attributed):
            attributed.baseType.baseFunctionTypeSyntax
        case .tupleType(let tuple):
            // It's hard to check for the necessity of throws keyword in multi-element tuples
            if tuple.elements.count == 1 {
                tuple.elements.first?.type.baseFunctionTypeSyntax
            } else {
                nil
            }
        default:
            nil
        }
    }
}
