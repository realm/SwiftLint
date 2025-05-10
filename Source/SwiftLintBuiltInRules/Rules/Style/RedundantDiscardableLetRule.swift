import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct RedundantDiscardableLetRule: Rule {
    var configuration = RedundantDiscardableLetConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_discardable_let",
        name: "Redundant Discardable Let",
        description: "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function",
        kind: .style,
        nonTriggeringExamples: [
            Example("_ = foo()"),
            Example("if let _ = foo() { }"),
            Example("guard let _ = foo() else { return }"),
            Example("let _: ExplicitType = foo()"),
            Example("while let _ = SplashStyle(rawValue: maxValue) { maxValue += 1 }"),
            Example("async let _ = await foo()"),
            Example("""
                var body: some View {
                    let _ = foo()
                    return Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true]),
        ],
        triggeringExamples: [
            Example("↓let _ = foo()"),
            Example("if _ = foo() { ↓let _ = bar() }"),
            Example("""
                var body: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """),
        ],
        corrections: [
            Example("↓let _ = foo()"): Example("_ = foo()"),
            Example("if _ = foo() { ↓let _ = bar() }"): Example("if _ = foo() { _ = bar() }"),
        ]
    )
}

private extension RedundantDiscardableLetRule {
    private enum CodeBlockKind {
        case normal
        case view
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var codeBlockScopes = Stack<CodeBlockKind>()

        override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
            codeBlockScopes.push(node.isViewBody ? .view : .normal)
            return .visitChildren
        }

        override func visitPost(_: AccessorBlockSyntax) {
            codeBlockScopes.pop()
        }

        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            codeBlockScopes.push(.normal)
            return .visitChildren
        }

        override func visitPost(_: CodeBlockSyntax) {
            codeBlockScopes.pop()
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if codeBlockScopes.peek() != .view || !configuration.ignoreSwiftUIViewBodies,
               node.bindingSpecifier.tokenKind == .keyword(.let),
               let binding = node.bindings.onlyElement,
               binding.pattern.is(WildcardPatternSyntax.self),
               binding.typeAnnotation == nil,
               !node.modifiers.contains(where: { $0.name.text == "async" }) {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.bindingSpecifier.positionAfterSkippingLeadingTrivia,
                        correction: .init(
                            start: node.bindingSpecifier.positionAfterSkippingLeadingTrivia,
                            end: binding.pattern.positionAfterSkippingLeadingTrivia,
                            replacement: ""
                        )
                    )
                )
            }
        }
    }
}

private extension AccessorBlockSyntax {
    var isViewBody: Bool {
        if let binding = parent?.as(PatternBindingSyntax.self),
           binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
           let type = binding.typeAnnotation?.type.as(SomeOrAnyTypeSyntax.self) {
            return type.someOrAnySpecifier.text == "some"
                && type.constraint.as(IdentifierTypeSyntax.self)?.name.text == "View"
                && binding.parent?.parent?.is(VariableDeclSyntax.self) == true
        }
        return false
    }
}
