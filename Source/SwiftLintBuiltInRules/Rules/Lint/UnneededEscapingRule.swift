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
        nonTriggeringExamples: [
            Example("""
            func outer(completion: @escaping () -> Void) { inner(completion: completion) }
            """),
            Example("""
            func returning(_ work: @escaping () -> Void) -> () -> Void { return work }
            """),
            Example("""
            func implicitlyReturning(g: @escaping () -> Void) -> () -> Void { g }
            """),
            Example("""
            struct S {
                var closure: (() -> Void)?
                mutating func setClosure(_ newValue: @escaping () -> Void) {
                    closure = newValue
                }
                mutating func setToSelf(_ newValue: @escaping () -> Void) {
                    self.closure = newValue
                }
            }
            """),
            Example("""
            func closure(completion: @escaping () -> Void) {
                DispatchQueue.main.async { completion() }
            }
            """),
            Example("""
            func capture(completion: @escaping () -> Void) {
                let closure = { completion() }
                closure()
            }
            """),
            Example("""
            func reassignLocal(completion: @escaping () -> Void) -> () -> Void {
                var local = { print("initial") }
                local = completion
                return local
            }
            """),
            Example("""
            func global(completion: @escaping () -> Void) {
                Global.completion = completion
            }
            """),
            Example("""
            func chain(c: @escaping () -> Void) -> () -> Void {
                let c1 = c
                if condition {
                    let c2 = c1
                    return c2
                }
                let c3 = c1
                return c3
            }
            """),
            Example("""
            var arrayOfCompletions = [() -> Void]()
            func array(completion: @escaping () -> Void) {
                var completions = [() -> Void]()
                completions[0] = completion
                arrayOfCompletions = completions
            }
            """, excludeFromDocumentation: true),
            Example("""
            var arrayOfCompletions = [() -> Void]()
            func array(completion: @escaping () -> Void) {
                arrayOfCompletions[0] = completion
            }
            """, excludeFromDocumentation: true),
            Example("""
            var _testSuiteFailedCallback: (() -> Void)?
            public func _setTestSuiteFailedCallback(_ callback: @escaping () -> Void) {
                _testSuiteFailedCallback = callback
            }
            """, excludeFromDocumentation: true),
            Example("""
            func f(c: @escaping () -> Void) {
                var cs = [() -> Void]()
                cs[0] = c
            }
            """, excludeFromDocumentation: true),
            Example("""
            func f(c: @escaping () -> Void) {
                var cs = [c]
            }
            """, excludeFromDocumentation: true),
            Example("""
            func f(c: @escaping () -> Void) {
                var cs = [1: c]
            }
            """, excludeFromDocumentation: true),
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
            Example("""
            func assignToLocal(completion: ↓@escaping () -> Void) {
                let local = completion
                local()
            }
            """),
            Example("""
            func reassignLocal(completion: ↓@escaping () -> Void) {
                var local = { print(\"initial\") }
                local = completion
                local()
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
    var taintedVariables = Set<String>()
    var doesEscape = false
    var inClosureContext = false

    init(paramName: String) {
        taintedVariables.insert(paramName)
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
        for argument in node.arguments where isTainted(argument.expression) {
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

private extension ExprSyntax {
    var baseNameToken: TokenSyntax? {
           `as`(DeclReferenceExprSyntax.self)?.baseName
        ?? `as`(MemberAccessExprSyntax.self)?.base?.baseNameToken
    }

    var isLocalVariable: Bool {
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
