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
            Example("""
                @ViewBuilder
                func bar() -> some View {
                    let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true]),
            Example("""
                #Preview {
                    let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true]),
            Example("""
                static var previews: some View {
                    let _ = foo()
                    Text("Hello, World!")
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
            Example("""
                @ViewBuilder
                func bar() -> some View {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """),
            Example("""
                #Preview {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """),
            Example("""
                static var previews: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """),
            Example("""
                var notBody: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true], excludeFromDocumentation: true),
            Example("""
                var body: some NotView {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true], excludeFromDocumentation: true),
        ],
        corrections: [
            Example("↓let _ = foo()"): Example("_ = foo()"),
            Example("if _ = foo() { ↓let _ = bar() }"): Example("if _ = foo() { _ = bar() }"),
            Example("""
                var body: some View {
                    ↓let _ = foo()
                    Text("Hello, World!")
                }
                """): Example("""
                    var body: some View {
                        _ = foo()
                        Text("Hello, World!")
                    }
                    """),
            Example("""
                #Preview {
                    ↓let _ = foo()
                    return Text("Hello, World!")
                }
                """): Example("""
                    #Preview {
                        _ = foo()
                        return Text("Hello, World!")
                    }
                    """),
            Example("""
                var body: some View {
                    let _ = foo()
                    return Text("Hello, World!")
                }
                """, configuration: ["ignore_swiftui_view_bodies": true]): Example("""
                    var body: some View {
                        let _ = foo()
                        return Text("Hello, World!")
                    }
                    """),
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
            codeBlockScopes.push(node.isViewBody || node.isPreviewProviderBody ? .view : .normal)
            return .visitChildren
        }

        override func visitPost(_: AccessorBlockSyntax) {
            codeBlockScopes.pop()
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            codeBlockScopes.push(node.isViewBuilderFunctionBody ? .view : .normal)
            return .visitChildren
        }

        override func visitPost(_: CodeBlockSyntax) {
            codeBlockScopes.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            codeBlockScopes.push(node.isPreviewMacroBody ? .view : .normal)
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
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
            return type.isView && binding.parent?.parent?.is(VariableDeclSyntax.self) == true
        }
        return false
    }

    var isPreviewProviderBody: Bool {
        guard let binding = parent?.as(PatternBindingSyntax.self),
              binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "previews",
              let bindingList = binding.parent?.as(PatternBindingListSyntax.self),
              let variableDecl = bindingList.parent?.as(VariableDeclSyntax.self),
              variableDecl.modifiers.contains(keyword: .static),
              variableDecl.bindingSpecifier.tokenKind == .keyword(.var),
              let type = binding.typeAnnotation?.type.as(SomeOrAnyTypeSyntax.self) else {
            return false
        }

        return type.isView
    }
}

private extension CodeBlockSyntax {
    var isViewBuilderFunctionBody: Bool {
        guard let functionDecl = parent?.as(FunctionDeclSyntax.self),
              functionDecl.attributes.contains(attributeNamed: "ViewBuilder") else {
            return false
        }
        return functionDecl.signature.returnClause?.type.as(SomeOrAnyTypeSyntax.self)?.isView ?? false
    }
}

private extension ClosureExprSyntax {
    var isPreviewMacroBody: Bool {
        parent?.as(MacroExpansionExprSyntax.self)?.macroName.text == "Preview"
    }
}

private extension SomeOrAnyTypeSyntax {
    var isView: Bool {
        someOrAnySpecifier.text == "some" &&
            constraint.as(IdentifierTypeSyntax.self)?.name.text == "View"
    }
}
