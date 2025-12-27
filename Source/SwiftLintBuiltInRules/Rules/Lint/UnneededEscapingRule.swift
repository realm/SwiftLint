import SwiftLexicalLookup
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, correctable: true, optIn: true)
struct UnneededEscapingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_escaping",
        name: "Unneeded Escaping",
        description: "The `@escaping` attribute should only be used when the closure actually escapes.",
        kind: .lint,
        nonTriggeringExamples: UnneededEscapingRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnneededEscapingRuleExamples.triggeringExamples,
        corrections: UnneededEscapingRuleExamples.corrections
    )
}

private extension UnneededEscapingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            checkFunction(parameters: node.signature.parameterClause, body: node.body?.statements)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            checkFunction(parameters: node.signature.parameterClause, body: node.body?.statements)
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if case let .getter(items) = node.accessorBlock?.accessors {
                checkFunction(parameters: node.parameterClause, body: items)
            } else if let getter = node.accessorBlock?.getAccessor {
                checkFunction(parameters: node.parameterClause, body: getter.body?.statements)
            }
        }

        private func checkFunction(parameters: FunctionParameterClauseSyntax, body: CodeBlockItemListSyntax?) {
            guard let body else {
                return
            }
            for param in parameters.parameters {
                if let escapingAttr = param.type.attribute(named: "escaping") {
                    validate(
                        paramName: (param.secondName ?? param.firstName).text,
                        with: escapingAttr,
                        isAutoclosure: param.type.attribute(named: "autoclosure") != nil,
                        in: body
                    )
                }
            }
        }

        private func validate(paramName: String,
                              with attr: AttributeSyntax,
                              isAutoclosure: Bool,
                              in body: CodeBlockItemListSyntax) {
            if EscapeChecker(paramName: paramName, isAutoclosure: isAutoclosure)
                .walk(tree: body, handler: \.doesEscape) {
                return
            }
            let correctionEndPosition =
                if case let .spaces(count) = attr.trailingTrivia.first, count > 0 {
                    attr.endPositionBeforeTrailingTrivia.advanced(by: 1)
                } else {
                    attr.endPositionBeforeTrailingTrivia
                }
            violations.append(
                .init(
                    position: attr.positionAfterSkippingLeadingTrivia,
                    reason: "@escaping attribute not required as '\(paramName)' does not escape",
                    correction: .init(
                        start: attr.positionAfterSkippingLeadingTrivia,
                        end: correctionEndPosition,
                        replacement: ""
                    )
                )
            )
        }
    }
}

private final class EscapeChecker: SyntaxVisitor {
    var taintedVariables = Set<String>()
    var doesEscape = false
    var inClosureContext = false
    let isAutoclosure: Bool

    init(paramName: String, isAutoclosure: Bool) {
        taintedVariables.insert(paramName)
        self.isAutoclosure = isAutoclosure
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: CodeBlockItemListSyntax) {
        if case let .expr(returnExpr) = node.onlyElement?.item, isTainted(returnExpr) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            if let initializer = binding.initializer,
               isTainted(initializer.value),
               let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                taintedVariables.insert(pattern.identifier.text)
            }
        }
    }

    override func visitPost(_ node: InfixOperatorExprSyntax) {
        guard node.operator.is(AssignmentExprSyntax.self), isTainted(node.rightOperand) else {
            return
        }
        if node.leftOperand.isLocalVariable {
            if let leftName = node.leftOperand.baseNameToken?.text {
                taintedVariables.insert(leftName)
            }
        } else {
            doesEscape = true
        }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
        if let expr = node.expression, isTainted(expr) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        for argument in node.arguments where isTainted(argument.expression) || usesTaintedCallee(argument.expression) {
            doesEscape = true
        }
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        inClosureContext = true
        return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
        inClosureContext = false
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        guard isTainted(ExprSyntax(node)) else {
            return
        }
        if inClosureContext || [.arrayElement, .dictionaryElement].contains(node.parent?.kind) {
            doesEscape = true
        }
    }

    private func isTainted(_ expr: ExprSyntax) -> Bool {
        if let declRef = expr.as(DeclReferenceExprSyntax.self) {
            return taintedVariables.contains(declRef.baseName.text)
        }
        if let optChain = expr.as(OptionalChainingExprSyntax.self),
           let declRef = optChain.expression.as(DeclReferenceExprSyntax.self) {
            return taintedVariables.contains(declRef.baseName.text)
        }
        if let ternary = expr.as(TernaryExprSyntax.self) {
            return isTainted(ternary.thenExpression) || isTainted(ternary.elseExpression)
        }
        return false
    }

    private func usesTaintedCallee(_ expr: ExprSyntax) -> Bool {
        guard isAutoclosure,
              let callExpr = expr.as(FunctionCallExprSyntax.self),
              callExpr.arguments.isEmpty,
              callExpr.trailingClosure == nil,
              callExpr.additionalTrailingClosures.isEmpty else {
            return false
        }
        return isTainted(callExpr.calledExpression)
    }
}

private extension TypeSyntax {
    func attribute(named name: String) -> AttributeSyntax? {
        if let attributeType = `as`(AttributedTypeSyntax.self) {
            return attributeType.attributes
                .compactMap { $0.as(AttributeSyntax.self) }
                .first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == name }
        }
        return `as`(OptionalTypeSyntax.self)?
            .wrappedType
            .as(TupleTypeSyntax.self)?
            .elements.onlyElement?.type
            .attribute(named: name)
    }
}

private extension ExprSyntax {
    var baseNameToken: TokenSyntax? {
           `as`(DeclReferenceExprSyntax.self)?.baseName
        ?? `as`(MemberAccessExprSyntax.self)?.base?.baseNameToken
    }

    var isLocalVariable: Bool {
        guard !`is`(DiscardAssignmentExprSyntax.self) else {
            return true
        }
        if let baseNameToken {
            let results = lookup(.init(baseNameToken))
            return results.isNotEmpty && results.allSatisfy {
                switch $0 {
                case .fromScope: true
                default: false
                }
            }
        }
        return false
    }
}
