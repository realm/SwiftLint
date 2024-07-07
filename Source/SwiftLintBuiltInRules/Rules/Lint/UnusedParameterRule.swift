import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct UnusedParameterRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_parameter",
        name: "Unused Parameter",
        description: """
            Other than unused local variable declarations, unused function/initializer/subscript parameters are not \
            marked by the Swift compiler. Since unused parameters are code smells, they should either be removed \
            or replaced/shadowed by a wildcard '_' to indicate that they are being deliberately disregarded.
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            func f(a: Int) {
                _ = a
            }
            """),
            Example("""
            func f(case: Int) {
                _ = `case`
            }
            """),
            Example("""
            func f(a _: Int) {}
            """),
            Example("""
            func f(_: Int) {}
            """),
            Example("""
            func f(a: Int, b c: String) {
                func g() {
                    _ = a
                    _ = c
                }
            }
            """),
            Example("""
            class C1: C2 {
                override func f(a: Int, b c: String) {}
            }
            """),
            Example("""
            func f(a: Int, c: Int) -> Int {
                struct S {
                    let b = 1
                    func f(a: Int, b: Int = 2) -> Int { a + b }
                }
                return a + c
            }
            """),
            Example("""
            func f(a: Int?) {
                if let a {}
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            func f(↓a: Int) {}
            """),
            Example("""
            func f(↓a: Int, b ↓c: String) {}
            """),
            Example("""
            func f(↓a: Int, b ↓c: String) {
                func g(a: Int, ↓b: Double) {
                    _ = a
                }
            }
            """),
            Example("""
            struct S {
                let a: Int

                init(a: Int, ↓b: Int) {
                    func f(↓a: Int, b: Int) -> Int { b }
                    self.a = f(a: a, b: 0)
                }
            }
            """),
            Example("""
            struct S {
                subscript(a: Int, ↓b: Int) {
                    func f(↓a: Int, b: Int) -> Int { b }
                    return f(a: a, b: 0)
                }
            }
            """),
            Example("""
            func f(↓a: Int, ↓b: Int, c: Int) -> Int {
                struct S {
                    let b = 1
                    func f(a: Int, ↓c: Int = 2) -> Int { a + b }
                }
                return S().f(a: c)
            }
            """),
        ]
    )
}

private class Parameter {
    fileprivate static let stopParameter = Parameter(position: .init(utf8Offset: 0), name: "")

    let position: AbsolutePosition
    let name: String
    var used = false

    init(position: AbsolutePosition, name: String) {
        self.position = position
        self.name = name
    }
}

private extension UnusedParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private static let parameterBoundary = [Parameter.stopParameter]

        private var declaredParameters = Stack<[Parameter]>()
        private var referencedVariables = Stack<Set<String>>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        // MARK: Parameter declarations

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if !node.modifiers.contains(keyword: .override) {
                initializeStacks(parameters: node.signature.parameterClause.parameters)
            }
            return .visitChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            if !node.modifiers.contains(keyword: .override) {
                initializeStacks(parameters: node.signature.parameterClause.parameters)
            }
            return .visitChildren
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            if !node.modifiers.contains(keyword: .override) {
                initializeStacks(parameters: node.parameterClause.parameters)
            }
            return .visitChildren
        }

        // MARK: Violation checking

        override func visitPost(_ node: FunctionDeclSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                collectViolations()
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                collectViolations()
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                collectViolations()
            }
        }

        // MARK: Reference collection

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            addReference(node.baseName.text)
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if node.initializer == nil, let id = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                addReference(id)
            }
        }

        // MARK: Type declaration boundaries

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            declaredParameters.push(Self.parameterBoundary)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            declaredParameters.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            declaredParameters.push(Self.parameterBoundary)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            declaredParameters.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            declaredParameters.push(Self.parameterBoundary)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            declaredParameters.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            declaredParameters.push(Self.parameterBoundary)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            declaredParameters.pop()
        }

        // MARK: Private methods

        private func initializeStacks(parameters: FunctionParameterListSyntax) {
            let parameters = parameters.compactMap {
                let name = $0.secondName ?? $0.firstName
                return name.tokenKind == .wildcard
                    ? nil
                    : Parameter(position: name.positionAfterSkippingLeadingTrivia, name: name.text)
            }
            declaredParameters.push(parameters)
            referencedVariables.push([])
        }

        private func addReference(_ id: String) {
            referencedVariables.modifyLast {
                $0.insert(id.trimmingCharacters(in: .init(charactersIn: "`")))
            }
        }

        private func collectViolations() {
            for reference in referencedVariables.pop() ?? [] {
                parameters: for parameters in declaredParameters.reversed() {
                    if parameters.onlyElement === Parameter.stopParameter {
                        break parameters
                    }
                    for parameter in parameters where reference == parameter.name {
                        parameter.used = true
                        break parameters
                    }
                }
            }
            (declaredParameters.pop() ?? [])
                .filter { !$0.used }
                .forEach {
                    let violation = ReasonedRuleViolation(
                        position: $0.position,
                        reason: "Parameter '\($0.name)' is unused; consider removing or replacing it with '_'",
                        severity: configuration.severity
                    )
                    violations.append(violation)
                }
        }
    }
}
