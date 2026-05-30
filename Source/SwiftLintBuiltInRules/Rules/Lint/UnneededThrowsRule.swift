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
        private var conformedProtocolsStack = Stack<[String]>()
        private lazy var throwingProtocolRequirements = ThrowingProtocolRequirementsCollector.requirements(in: file)

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [
                ProtocolDeclSyntax.self,
                TypeAliasDeclSyntax.self,
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

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            conformedProtocolsStack.push(node.inheritedProtocolNames)
            return .visitChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            conformedProtocolsStack.closeScope()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            conformedProtocolsStack.push(node.inheritedProtocolNames)
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            conformedProtocolsStack.closeScope()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            conformedProtocolsStack.push(node.inheritedProtocolNames)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            conformedProtocolsStack.closeScope()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            conformedProtocolsStack.push(node.inheritedProtocolNames)
            return .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            conformedProtocolsStack.closeScope()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.openScope(with: node.signature.effectSpecifiers?.throwsClause)
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let closedScope = scopes.closeScope() {
                guard !isThrowsRequiredByProtocolConformance(functionName: node.name.text) else {
                    return
                }

                validate(
                    scope: closedScope,
                    construct: "body of this function"
                )
            }
        }

        override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
            if let lintableFunctionType = node.lintableFunctionType {
                scopes.openScope(with: lintableFunctionType.effectSpecifiers?.throwsClause)
            }
            return .visitChildren
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if node.lintableFunctionType != nil {
                if let closedScope = scopes.closeScope() {
                    validate(
                        scope: closedScope,
                        construct: "closure type"
                    )
                }
            }
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            if let throwsClause = node.signature?.effectSpecifiers?.throwsClause {
                scopes.openScope(with: throwsClause)
            }
            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if node.signature?.effectSpecifiers?.throwsClause != nil, let closedScope = scopes.closeScope() {
                validate(
                    scope: closedScope,
                    construct: "body of this closure"
                )
            }
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            walk(node.calledExpression)
            walk(node.arguments)
            if node.hasTrailingClosures {
                scopes.openScope()
                if let trailingClosure = node.trailingClosure {
                    walk(trailingClosure)
                }
                walk(node.additionalTrailingClosures)
            }
            return .skipChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasTrailingClosures {
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

        private func isThrowsRequiredByProtocolConformance(functionName: String) -> Bool {
            for protocolName in conformedProtocolsStack.flatMap({ $0 }) {
                if throwingProtocolRequirements[protocolName]?.contains(functionName) == true {
                    return true
                }
            }

            return false
        }

        private func validate(scope: Scope, construct: String) {
            guard let throwsClause = scope.throwsClause else { return }
            violations.append(
                .init(
                    position: throwsClause.positionAfterSkippingLeadingTrivia,
                    reason: "Superfluous 'throws'; \(construct) does not throw any error",
                    correction: .init(
                        // Move start position back by 1 to include the space before the keyword.
                        start: throwsClause.positionAfterSkippingLeadingTrivia.advanced(by: -1),
                        end: throwsClause.endPositionBeforeTrailingTrivia,
                        replacement: ""
                    )
                )
            )
        }
    }
}

private enum ThrowingProtocolRequirementsCollector {
    static func requirements(in file: SwiftLintFile) -> [String: Set<String>] {
        ThrowingProtocolRequirementsVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.requirements)
    }
}

private final class ThrowingProtocolRequirementsVisitor: SyntaxVisitor {
    private(set) var requirements = [String: Set<String>]()

    override func visitPost(_ node: ProtocolDeclSyntax) {
        var throwingMethods = Set<String>()

        for member in node.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  function.signature.effectSpecifiers?.throwsClause != nil else {
                continue
            }

            throwingMethods.insert(function.name.text)
        }

        if throwingMethods.isNotEmpty {
            requirements[node.name.text] = throwingMethods
        }
    }
}

private extension Stack where Element == [String] {
    mutating func closeScope() {
        pop()
    }
}

private extension InheritedTypeListSyntax {
    var protocolNames: [String] {
        compactMap { inheritedType in
            inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text
        }
    }
}

private extension ActorDeclSyntax {
    var inheritedProtocolNames: [String] {
        inheritanceClause?.inheritedTypes.protocolNames ?? []
    }
}

private extension ClassDeclSyntax {
    var inheritedProtocolNames: [String] {
        inheritanceClause?.inheritedTypes.protocolNames ?? []
    }
}

private extension StructDeclSyntax {
    var inheritedProtocolNames: [String] {
        inheritanceClause?.inheritedTypes.protocolNames ?? []
    }
}

private extension ExtensionDeclSyntax {
    var inheritedProtocolNames: [String] {
        inheritanceClause?.inheritedTypes.protocolNames ?? []
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
    var hasTrailingClosures: Bool {
        trailingClosure != nil || additionalTrailingClosures.isNotEmpty
    }
}

private extension PatternBindingSyntax {
    private var hasNonReferenceInitializer: Bool {
        ![.declReferenceExpr, .memberAccessExpr, .functionCallExpr, nil].contains(initializer?.value.kind)
    }

    private var isLetBinding: Bool {
        parent?.as(PatternBindingListSyntax.self)?
            .parent?.as(VariableDeclSyntax.self)?
            .bindingSpecifier.tokenKind == .keyword(.let)
    }

    var lintableFunctionType: FunctionTypeSyntax? {
        guard isLetBinding, hasNonReferenceInitializer else {
            return nil
        }
        return typeAnnotation?.type.baseFunctionTypeSyntax
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
            // It's hard to check for the necessity of throws keyword in multi-element tuples.
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
