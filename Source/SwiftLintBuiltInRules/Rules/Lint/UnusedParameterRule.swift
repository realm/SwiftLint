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

// MARK: Visitor

private extension UnusedParameterRule {
    final class Visitor: DeclaredIdentifiersTrackingVisitor<ConfigurationType> {
        private var referencedParameters = Set<Declaration>()
        private var referencedVariables = Stack<Set<String>>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        // MARK: Parameter declarations

        override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
            if node.grandParent?.isNonOverriddenFunctionLike == true {
                referencedVariables.push([])
            }
            return super.visit(node)
        }

        // MARK: Violation checking

        override func visitPost(_ node: CodeBlockItemListSyntax) {
            if node.grandParent?.isNonOverriddenFunctionLike == true {
                collectViolations()
            }
            super.visitPost(node)
        }

        // MARK: Reference collection

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if node.keyPathInParent != \MemberAccessExprSyntax.declName {
                addReference(node.baseName.text)
            }
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if node.initializer == nil, let id = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                addReference(id)
            }
        }

        // MARK: Private methods

        private func addReference(_ id: String) {
            referencedVariables.modifyLast { $0.insert(id.trimmingCharacters(in: .init(charactersIn: "`"))) }
        }

        private func collectViolations() {
            var variables = referencedVariables.pop() ?? []
            for declarations in scope.reversed() {
                if declarations.onlyElement == .stopMarker {
                    break
                }
                for declaration in declarations where !referencedParameters.contains(declaration) {
                    guard case let .parameter(position, name) = declaration else {
                        continue
                    }
                    if variables.contains(name) {
                        variables.remove(name)
                        referencedParameters.insert(declaration)
                        continue
                    }
                    let violation = ReasonedRuleViolation(
                        position: position,
                        reason: "Parameter '\(name)' is unused; consider removing or replacing it with '_'",
                        severity: configuration.severity
                    )
                    violations.append(violation)
                }
                if variables.isEmpty {
                    return
                }
            }
        }
    }
}

private extension SyntaxProtocol {
    var grandParent: Syntax? {
        if let parent, !parent.is(SourceFileSyntax.self) {
            return parent.parent
        }
        return nil
    }

    var isNonOverriddenFunctionLike: Bool {
        if [.functionDecl, .initializerDecl, .subscriptDecl].contains(kind),
           let modifiers = asProtocol((any WithModifiersSyntax).self)?.modifiers {
            return !modifiers.contains(keyword: .override)
        }
        return false
    }
}
