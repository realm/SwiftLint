import SwiftSyntax

@SwiftSyntaxRule
struct PreferSelfInStaticReferencesRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description = RuleDescription(
        identifier: "prefer_self_in_static_references",
        name: "Prefer Self in Static References",
        description: "Use `Self` to refer to the surrounding type name",
        kind: .style,
        nonTriggeringExamples: PreferSelfInStaticReferencesRuleExamples.nonTriggeringExamples,
        triggeringExamples: PreferSelfInStaticReferencesRuleExamples.triggeringExamples,
        corrections: PreferSelfInStaticReferencesRuleExamples.corrections
    )
}

extension PreferSelfInStaticReferencesRule {
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

    final class Visitor: ViolationsSyntaxVisitor {
        private var parentDeclScopes = Stack<ParentDeclBehavior>()
        private var variableDeclScopes = Stack<VariableDeclBehavior>()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeClass(name: node.name.text))
            return .skipChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
            if case .skipReferences = variableDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeClass(name: node.name.text))
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
            variableDeclScopes.push(.handleReferences)
            return .visitChildren
        }

        override func visitPost(_ node: CodeBlockItemListSyntax) {
            variableDeclScopes.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeStruct(node.name.text))
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.skipReferences)
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
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

        override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .skipReferences = variableDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                variableDeclScopes.push(.skipReferences)
            } else {
                variableDeclScopes.push(.handleReferences)
            }
            return .visitChildren
        }

        override func visitPost(_ node: MemberBlockSyntax) {
            variableDeclScopes.pop()
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek(), case .identifier("selector") = node.macroName.tokenKind {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .likeStruct = parentDeclScopes.peek() {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.skipReferences)
            return .skipChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
            if case .likeStruct = parentDeclScopes.peek() {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            parentDeclScopes.push(.likeStruct(node.name.text))
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
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

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
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
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true     // Local variable declaration
                    || varDecl.bindings.onlyElement?.accessorBlock != nil   // Computed property
                    || !node.type.is(IdentifierTypeSyntax.self)             // Complex or collection type
                {
                    return .visitChildren
                }
            }
            return .skipChildren
        }

        private func addViolation(on node: TokenSyntax) {
            if let parentName = parentDeclScopes.peek()?.parentName, node.tokenKind == .identifier(parentName) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
                violationCorrections.append(
                    ViolationCorrection(
                        start: node.positionAfterSkippingLeadingTrivia,
                        end: node.endPositionBeforeTrailingTrivia,
                        replacement: "Self"
                    )
                )
            }
        }
    }
}
