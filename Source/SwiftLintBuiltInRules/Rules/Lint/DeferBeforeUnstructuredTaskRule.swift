import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct DeferBeforeUnstructuredTaskRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "defer_before_unstructured_task",
        name: "Defer Before Unstructured Task",
        description: """
            A `defer` block runs the moment its enclosing synchronous scope returns, before a sibling \
            unstructured `Task` has a chance to run its body. Assigning to shared state in such a `defer` \
            while a `Task` in the same scope reads that state is usually a bug: the state is reset before \
            the asynchronous work it's guarding has actually finished. Move the assignment inside the \
            `Task`, or make the enclosing function `async` and `await` the work directly
            """,
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            func f() async {
                isLoading = true
                defer { isLoading = false }
                await work()
            }
            """,
            """
            func f() {
                defer { print("done") }
                Task { await work() }
            }
            """,
            """
            func f() {
                let t = Task { await work() }
                defer { print("leaving") }
                _ = t
            }
            """,
            """
            func f() {
                var localFlag = true
                defer { localFlag = false }
                Task { await work() }
                _ = localFlag
            }
            """,
            """
            func f() {
                isLoading = true
                defer { isLoading = false }
                let t = Task {
                    await work()
                    _ = isLoading
                }
                _ = t
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            func login() {
                isLoading = true
                ↓defer { isLoading = false }
                Task {
                    await doSomethingAsync()
                    _ = isLoading
                }
            }
            """,
            """
            func login() {
                isLoading = true
                ↓defer { isLoading = false }
                Task.detached {
                    await doSomethingAsync()
                    _ = await self.isLoading
                }
            }
            """,
            """
            func login() {
                isLoading = true
                errorMessage = nil
                ↓defer {
                    isLoading = false
                    errorMessage = nil
                }
                Task {
                    await doSomethingAsync()
                    _ = isLoading
                }
            }
            """,
            """
            func login() {
                isLoading = true
                ↓defer { isLoading = false }
                Task<Void, Never> {
                    await doSomethingAsync()
                    _ = isLoading
                }
            }
            """,
        ])
    )
}

private extension DeferBeforeUnstructuredTaskRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeferStmtSyntax) {
            guard
                !node.isInAsyncScope,
                let identifiers = node.assignedIdentifiers,
                node.hasSiblingDiscardedTask(referencing: identifiers)
            else {
                return
            }

            violations.append(node.deferKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension DeferStmtSyntax {
    /// Whether the nearest enclosing function-like scope is `async`.
    var isInAsyncScope: Bool {
        var current = parent
        while let node = current {
            if let function = node.as(FunctionDeclSyntax.self) {
                return function.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            if let closure = node.as(ClosureExprSyntax.self) {
                return closure.signature?.effectSpecifiers?.asyncSpecifier != nil
            }
            if let accessor = node.as(AccessorDeclSyntax.self) {
                return accessor.effectSpecifiers?.asyncSpecifier != nil
            }
            if let initializer = node.as(InitializerDeclSyntax.self) {
                return initializer.signature.effectSpecifiers?.asyncSpecifier != nil
            }
            current = node.parent
        }
        return false
    }

    /// The identifiers simply assigned to in this `defer`'s body, if the body consists of one or two
    /// straightforward assignments only. Returns `nil` for anything else (logging calls, lock releases,
    /// control flow, etc.), which excludes those defers from consideration.
    var assignedIdentifiers: Set<String>? {
        let statements = body.statements
        guard (1...2).contains(statements.count) else {
            return nil
        }

        var identifiers = Set<String>()
        for statement in statements {
            guard
                let infix = statement.item.as(InfixOperatorExprSyntax.self),
                infix.operator.is(AssignmentExprSyntax.self),
                let identifier = infix.leftOperand.assignmentTargetIdentifier
            else {
                return nil
            }
            identifiers.insert(identifier)
        }

        return identifiers
    }

    /// Whether a sibling statement at the same scope as this `defer` is a discarded `Task { ... }` or
    /// `Task.detached { ... }` call whose trailing closure references at least one of `identifiers`.
    func hasSiblingDiscardedTask(referencing identifiers: Set<String>) -> Bool {
        guard let siblings = parent?.parent?.as(CodeBlockItemListSyntax.self) else {
            return false
        }

        return siblings.contains { sibling in
            guard
                let call = sibling.item.as(FunctionCallExprSyntax.self),
                call.isUnstructuredTaskInitializer,
                let closure = call.trailingClosure
            else {
                return false
            }

            return closure.references(any: identifiers)
        }
    }
}

private extension ExprSyntax {
    /// The identifier this expression assigns to, considering plain identifiers (`foo`) and
    /// `self`-qualified member access (`self.foo`). `nil` for anything more complex.
    var assignmentTargetIdentifier: String? {
        if let reference = `as`(DeclReferenceExprSyntax.self) {
            return reference.baseName.text
        }

        if let member = `as`(MemberAccessExprSyntax.self),
           member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "self" {
            return member.declName.baseName.text
        }

        return nil
    }
}

private extension FunctionCallExprSyntax {
    var isUnstructuredTaskInitializer: Bool {
        if let reference = calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "Task"
        }

        if let specialized = calledExpression.as(GenericSpecializationExprSyntax.self),
           let reference = specialized.expression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "Task"
        }

        if let member = calledExpression.as(MemberAccessExprSyntax.self),
           member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Task",
           member.declName.baseName.text == "detached" {
            return true
        }

        return false
    }
}

private extension ClosureExprSyntax {
    func references(any identifiers: Set<String>) -> Bool {
        IdentifierReferenceVisitor(identifiers: identifiers, viewMode: .sourceAccurate)
            .walk(tree: self, handler: \.found)
    }
}

private final class IdentifierReferenceVisitor: SyntaxVisitor {
    private let identifiers: Set<String>
    var found = false

    init(identifiers: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.identifiers = identifiers
        super.init(viewMode: viewMode)
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        if identifiers.contains(node.baseName.text) {
            found = true
        }
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
        if node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "self",
           identifiers.contains(node.declName.baseName.text) {
            found = true
        }
    }
}
