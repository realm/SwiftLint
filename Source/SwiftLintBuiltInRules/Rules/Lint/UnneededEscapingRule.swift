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
        nonTriggeringExamples: [
            Example("""
            func outer(completion: @escaping () -> Void) { inner(completion: completion) }
            """),
            Example("""
            func apply(_ work: @escaping () -> Void) -> () -> Void { return work }
            """),
            Example("""
            func f(g: @escaping () -> Void) -> () -> Void { g }
            """),
            Example("""
            func store(completion: @escaping () -> Void) { self.c = completion }
            """),
            Example("""
            func async(completion: @escaping () -> Void) {
                DispatchQueue.main.async { completion() }
            }
            """),
            Example("""
            func capture(completion: @escaping () -> Void) {
                let closure = { completion() }
                closure()
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            func forEach(action: ↓@escaping (Int) -> Void) {
                for i in 0..<10 {
                    action(i)
                }
            }
            """),
            Example("""
            func process(completion: ↓@escaping () -> Void) {
                completion()
            }
            """),
            Example("""
            func apply(_ transform: ↓@escaping (Int) -> Int) -> Int {
                return transform(5)
            }
            """),
            Example("""
            func optional(completion: (↓@escaping () -> Void)?) {
                completion?()
            }
            """),
            Example("""
            func multiple(first: ↓@escaping () -> Void, second: ↓@escaping () -> Void) {
                first()
                second()
            }
            """),
            Example("""
            subscript(transform: ↓@escaping (Int) -> String) -> String {
                transform(42)
            }
            """),
        ],
        corrections: [
            Example("""
            func forEach(action: ↓@escaping (Int) -> Void) {
                for i in 0..<10 {
                    action(i)
                }
            }
            """): Example("""
                func forEach(action: (Int) -> Void) {
                    for i in 0..<10 {
                        action(i)
                    }
                }
                """),
            Example("""
            func process(completion: ↓@escaping () -> Void) { completion() }
            """): Example("""
                func process(completion: () -> Void) { completion() }
                """),
            Example("""
            subscript(transform: ↓@escaping (Int) -> String) -> String { transform(42) }
            """): Example("""
                subscript(transform: (Int) -> String) -> String { transform(42) }
                """),
            Example("""
            func f(c: ↓@escaping() -> Void) { c() }
            """): Example("""
                func f(c: () -> Void) { c() }
                """),
        ]
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
                if let escapingAttr = param.type.escapingAttribute {
                    validate(paramName: (param.secondName ?? param.firstName).text, with: escapingAttr, in: body)
                }
            }
        }

        private func validate(paramName: String, with attr: AttributeSyntax, in body: CodeBlockItemListSyntax) {
            if EscapeChecker(paramName: paramName).walk(tree: body, handler: \.doesEscape) {
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
    let paramName: String
    var doesEscape = false
    var inClosureContext = false

    init(paramName: String) {
        self.paramName = paramName
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: CodeBlockItemListSyntax) {
        if case let .expr(returnExpr) = node.onlyElement?.item, referencesParameter(returnExpr) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: InfixOperatorExprSyntax) {
        if node.operator.is(AssignmentExprSyntax.self),
           node.leftOperand.is(DeclReferenceExprSyntax.self) || node.leftOperand.is(MemberAccessExprSyntax.self),
           referencesParameter(node.rightOperand) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
        if let expr = node.expression, referencesParameter(expr) {
            doesEscape = true
        }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        for argument in node.arguments where referencesParameter(argument.expression) {
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
        if inClosureContext, referencesParameter(ExprSyntax(node)) {
            doesEscape = true
        }
    }

    private func referencesParameter(_ expr: ExprSyntax) -> Bool {
        if let declRef = expr.as(DeclReferenceExprSyntax.self) {
            return declRef.baseName.text == paramName
        }
        if let optChain = expr.as(OptionalChainingExprSyntax.self),
           let declRef = optChain.expression.as(DeclReferenceExprSyntax.self) {
            return declRef.baseName.text == paramName
        }
        return false
    }
}

private extension TypeSyntax {
    var escapingAttribute: AttributeSyntax? {
        if let attributeType = `as`(AttributedTypeSyntax.self) {
            return attributeType.attributes
                .compactMap { $0.as(AttributeSyntax.self) }
                .first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "escaping" }
        }
        if let optionalType = `as`(OptionalTypeSyntax.self) {
            return optionalType.wrappedType.as(TupleTypeSyntax.self)?.elements.first?.type.escapingAttribute
        }
        return nil
    }
}
