import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct PreferSelfInStaticReferencesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_self_in_static_references",
        name: "Prefer Self in Static References",
        description: "Use `Self` to refer to the surrounding type name",
        kind: .style,
        nonTriggeringExamples: PreferSelfInStaticReferencesRuleExamples.nonTriggeringExamples,
        triggeringExamples: PreferSelfInStaticReferencesRuleExamples.triggeringExamples,
        corrections: PreferSelfInStaticReferencesRuleExamples.corrections
    )
}

private extension PreferSelfInStaticReferencesRule {
    private enum ParentDeclBehavior {
        case likeClass(name: String)
        case likeStruct(String)
        case skipReferences

        var parentName: String? {
            switch self {
            case let .likeClass(name): return name
            case let .likeStruct(name): return name
            case .skipReferences: return nil
            }
        }
    }

    private enum VariableDeclBehavior {
        case handleReferences
        case skipReferences
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var parentDeclScopes = Stack<ParentDeclBehavior>()
        private var variableDeclScopes = Stack<VariableDeclBehavior>()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeClass(name: node.name.text))
            return .skipChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_: AttributeSyntax) -> SyntaxVisitorContinueKind {
            if case .skipReferences = variableDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeClass(name: node.name.text))
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
            variableDeclScopes.push(.handleReferences)
            return .visitChildren
        }

        override func visitPost(_: CodeBlockItemListSyntax) {
            variableDeclScopes.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeStruct(node.name.text))
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.skipReferences)
            return .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                if node.declName.baseName.tokenKind == .keyword(.self) {
                    return .skipChildren
                }
            }
            return .visitChildren
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            guard let parent = node.parent, !parent.is(GenericSpecializationExprSyntax.self),
                  node.keyPathInParent != \MemberAccessExprSyntax.declName else {
                return
            }
            if parent.is(FunctionCallExprSyntax.self), case .likeClass = parentDeclScopes.peek() {
                return
            }
            addViolation(on: node.baseName)
        }

        override func visit(_: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .skipReferences = variableDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                variableDeclScopes.push(.skipReferences)
            } else {
                variableDeclScopes.push(.handleReferences)
            }
            return .visitChildren
        }

        override func visitPost(_: MemberBlockSyntax) {
            variableDeclScopes.pop()
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek(), case .identifier("selector") = node.macroName.tokenKind {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .likeStruct = parentDeclScopes.peek() {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.skipReferences)
            return .skipChildren
        }

        override func visitPost(_: ProtocolDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .likeStruct = parentDeclScopes.peek() {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeStruct(node.name.text))
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_: GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visitPost(_ node: IdentifierTypeSyntax) {
            guard let parent = node.parent else {
                return
            }
            if case .likeClass = parentDeclScopes.peek(), parent.is(GenericArgumentSyntax.self) {
                // Type is a generic parameter in a class.
                return
            }
            if node.genericArguments == nil {
                // Type is specialized.
                addViolation(on: node.name)
            }
        }

        override func visit(_: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
            guard case .likeStruct = parentDeclScopes.peek() else {
                return .skipChildren
            }
            if let varDecl = node.parent?.parent?.parent?.as(VariableDeclSyntax.self) {
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true    // Local variable declaration
                   || varDecl.bindings.onlyElement?.accessorBlock != nil   // Computed property
                   || !node.type.is(IdentifierTypeSyntax.self) {           // Complex or collection type
                    return .visitChildren
                }
            }
            return .skipChildren
        }

        private func addViolation(on node: TokenSyntax) {
            if let parentName = parentDeclScopes.peek()?.parentName, node.tokenKind == .identifier(parentName) {
                violations.append(
                    at: node.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: node.positionAfterSkippingLeadingTrivia,
                        end: node.endPositionBeforeTrailingTrivia,
                        replacement: "Self"
                    )
                )
            }
        }
    }
}
