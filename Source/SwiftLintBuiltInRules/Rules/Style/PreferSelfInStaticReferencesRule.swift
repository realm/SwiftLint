// swiftlint:disable file_length

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
    private enum ExtendedType {
        /// A type named by a plain identifier, e.g. `extension Foo`.
        case identifier(String)
        /// A member type, e.g. `extension Foo.Bar`, stored as its component path.
        case memberType([String])
    }

    private enum ParentDeclBehavior {
        case likeClass(ExtendedType)
        case likeStruct(String)
        case skipReferences

        /// The single identifier matched for token-based violations and for the
        /// nested-type shadowing check. `nil` for member-type extensions, which
        /// are matched structurally instead.
        var parentName: String? {
            switch self {
            case let .likeClass(.identifier(name)): return name
            case .likeClass(.memberType): return nil
            case let .likeStruct(name): return name
            case .skipReferences: return nil
            }
        }

        /// The component path of a member-type extension, e.g. `["Foo", "Bar"]`,
        /// or `nil` for any other scope.
        var memberTypeComponents: [String]? {
            if case let .likeClass(.memberType(components)) = self {
                return components
            }
            return nil
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
            pushParentDeclScope(.likeClass(.identifier(node.name.text)), memberBlock: node.memberBlock)
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
            pushParentDeclScope(.likeClass(.identifier(node.name.text)), memberBlock: node.memberBlock)
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
            pushParentDeclScope(.likeStruct(node.name.text), memberBlock: node.memberBlock)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            parentDeclScopes.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            // Treat the extended type as a class. Without knowing the exact
            // declaration kind, this is the most conservative scope that still
            // surfaces violations on member-access expressions inside methods,
            // computed properties and closure bodies. Cases the class scope
            // already skips (e.g. stored-property initializers, function
            // signatures) remain skipped to avoid false positives.
            if let type = extendedType(of: node.extendedType) {
                pushParentDeclScope(.likeClass(type), memberBlock: node.memberBlock)
            } else {
                parentDeclScopes.push(.skipReferences)
            }
            return .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            parentDeclScopes.pop()
        }

        private func extendedType(of type: TypeSyntax) -> ExtendedType? {
            if let identifier = type.as(IdentifierTypeSyntax.self) {
                return .identifier(identifier.name.text)
            }
            if let memberType = type.as(MemberTypeSyntax.self), let tokens = memberTypeChain(memberType) {
                return .memberType(tokens.map(\.text))
            }
            return nil
        }

        override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                if node.declName.baseName.tokenKind == .keyword(.self) {
                    return .skipChildren
                }
            }
            // In a member-type extension (e.g. `extension Foo.Bar`), match the
            // extended-type access chain structurally; a single token can't
            // disambiguate `Outer.Inner.x` from `Other.Inner.x`. Skip when the
            // path is the callee of a call or carries explicit generic
            // arguments (`Foo.Bar()`, `Foo.Bar<Int>()`), since `Self` doesn't
            // substitute for those.
            if let components = parentDeclScopes.peek()?.memberTypeComponents,
               node.parent?.is(FunctionCallExprSyntax.self) != true,
               node.parent?.is(GenericSpecializationExprSyntax.self) != true,
               let tokens = memberAccessChain(node),
               tokens.map(\.text) == components {
                addMemberTypeViolation(spanning: tokens)
                return .skipChildren
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
            pushParentDeclScope(.likeStruct(node.name.text), memberBlock: node.memberBlock)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            parentDeclScopes.pop()
        }

        // A composition (`A & B`) must not have the enclosing type rewritten to
        // `Self`: that changes the composition's meaning (and `Self & B` is not
        // even valid when the enclosing type is a protocol). Skip the whole
        // construct so neither identifier nor member-type components are flagged.
        override func visit(_: CompositionTypeSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        // The constraint of an existential or opaque type (`any A`, `some A`, and
        // the composition in `any A & B`) must not be rewritten to `Self`:
        // `any Self`/`some Self` is not valid. Skip the whole construct.
        override func visit(_: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        // The base of an existential metatype `P.Protocol` must not be rewritten
        // to `Self`: `Self.Protocol` is invalid because `Self` is a concrete type.
        // Only `.Protocol` is skipped; `.Type` metatypes stay correctable, since
        // `Self.Type` is valid.
        override func visit(_ node: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek(), node.metatypeSpecifier.tokenKind == .keyword(.Protocol) {
                return .skipChildren
            }
            return .visitChildren
        }

        // The type operand of an `is` / `as` / `as?` / `as!` cast must not be
        // rewritten to `Self` in a class-like scope: `Self` is the dynamic type,
        // so `x is Self` is not equivalent to `x is A` for a non-final class (an
        // instance of a subclass satisfies `is Self` but not the intended base
        // type). This mirrors the `X.self` skip; static member references
        // (`A.f()`) are unaffected because they are not cast operands.
        override func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek(), isCastOperand(node) {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_: GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_: GenericParameterListSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visit(_: GenericRequirementListSyntax) -> SyntaxVisitorContinueKind {
            if case .likeClass = parentDeclScopes.peek() {
                return .skipChildren
            }
            return .visitChildren
        }

        override func visitPost(_ node: IdentifierTypeSyntax) {
            guard let parent = node.parent else {
                return
            }
            // Don't flag identifiers that belong to the extension declaration
            // header (the extended type itself); the new class-like scope
            // pushed for the extension would otherwise rewrite it to `Self`.
            if parent.is(ExtensionDeclSyntax.self) {
                return
            }
            if node.genericArguments == nil {
                // Type is specialized.
                addViolation(on: node.name)
            }
        }

        override func visitPost(_ node: MemberTypeSyntax) {
            guard let components = parentDeclScopes.peek()?.memberTypeComponents else {
                return
            }
            // Don't flag the extended type in the extension header itself.
            if node.parent?.is(ExtensionDeclSyntax.self) == true {
                return
            }
            // Mirror the single-identifier rule: a type appearing as a generic
            // argument is left alone, since `Self` may not be available in that
            // position (e.g. an extension's own inheritance clause).
            if node.parent?.is(GenericArgumentSyntax.self) == true {
                return
            }
            if let tokens = memberTypeChain(node), tokens.map(\.text) == components {
                addMemberTypeViolation(spanning: tokens)
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

        /// Whether `node` is the type operand of an `is` / `as` / `as?` / `as!`
        /// cast. A bare type expression only ends up as an element of a sequence
        /// expression in that position, and `ExprListSyntax` is used solely for a
        /// sequence's elements, so the parent check is sufficient (and avoids
        /// scanning the sequence).
        private func isCastOperand(_ node: TypeExprSyntax) -> Bool {
            node.parent?.is(ExprListSyntax.self) == true
        }

        private func addViolation(on node: TokenSyntax) {
            if let parentName = parentDeclScopes.peek()?.parentName,
               node.tokenKind == .identifier(parentName) {
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

        private func addMemberTypeViolation(spanning tokens: [TokenSyntax]) {
            guard let first = tokens.first, let last = tokens.last else {
                return
            }
            let start = first.positionAfterSkippingLeadingTrivia
            violations.append(
                at: start,
                correction: .init(
                    start: start,
                    end: last.endPositionBeforeTrailingTrivia,
                    replacement: "Self"
                )
            )
        }

        /// Flattens an expression member-access chain (e.g. `Foo.Bar`) into its
        /// component tokens, or `nil` if the chain is not a plain type path.
        private func memberAccessChain(_ node: MemberAccessExprSyntax) -> [TokenSyntax]? {
            var tokens = [node.declName.baseName]
            var base = node.base
            while let member = base?.as(MemberAccessExprSyntax.self) {
                tokens.insert(member.declName.baseName, at: 0)
                base = member.base
            }
            guard let reference = base?.as(DeclReferenceExprSyntax.self) else {
                return nil
            }
            tokens.insert(reference.baseName, at: 0)
            return tokens
        }

        /// Flattens a member type (e.g. `Foo.Bar`) into its component tokens, or
        /// `nil` if the type is not a plain member path. Member types carrying
        /// generic arguments are excluded, since `Self` cannot stand in for them.
        private func memberTypeChain(_ node: MemberTypeSyntax) -> [TokenSyntax]? {
            guard node.genericArgumentClause == nil else {
                return nil
            }
            var tokens = [node.name]
            var base = node.baseType
            while let member = base.as(MemberTypeSyntax.self) {
                guard member.genericArgumentClause == nil else {
                    return nil
                }
                tokens.insert(member.name, at: 0)
                base = member.baseType
            }
            guard let identifier = base.as(IdentifierTypeSyntax.self),
                  identifier.genericArgumentClause == nil else {
                return nil
            }
            tokens.insert(identifier.name, at: 0)
            return tokens
        }

        private func pushParentDeclScope(_ behavior: ParentDeclBehavior, memberBlock: MemberBlockSyntax) {
            let hasShadowingNestedType =
                if let name = behavior.parentName {
                    containsSameNamedNestedType(named: name, in: memberBlock)
                } else {
                    false
                }
            parentDeclScopes.push(hasShadowingNestedType ? .skipReferences : behavior)
        }

        private func containsSameNamedNestedType(named name: String, in memberBlock: MemberBlockSyntax) -> Bool {
            memberBlock.members.contains { member in
                if member.decl.isProtocol((any DeclGroupSyntax).self) || member.decl.is(TypeAliasDeclSyntax.self) {
                    return member.decl.asProtocol((any NamedDeclSyntax).self)?.name.text == name
                }

                return false
            }
        }
    }
}
