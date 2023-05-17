import SwiftSyntax

struct PreferSelfInStaticReferencesRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule, OptInRule {
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let ranges = Visitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.corrections)
            .compactMap { file.stringView.NSRange(start: $0.start, end: $0.end) }
            .filter { file.ruleEnabled(violatingRange: $0, for: self) != nil }
            .reversed()

        var corrections = [Correction]()
        var contents = file.contents
        for range in ranges {
            let contentsNSString = contents.bridge()
            contents = contentsNSString.replacingCharacters(in: range, with: "Self")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: Self.description, location: location))
        }

        file.write(contents)

        return corrections
    }
}

private class Visitor: ViolationsSyntaxVisitor {
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

    private var parentDeclScopes = Stack<ParentDeclBehavior>()
    private var variableDeclScopes = Stack<VariableDeclBehavior>()
    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.push(.likeClass(name: node.identifier.text))
        return .skipChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        parentDeclScopes.pop()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.push(.likeClass(name: node.identifier.text))
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        parentDeclScopes.pop()
    }

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        variableDeclScopes.push(.handleReferences)
        return .visitChildren
    }

    override func visitPost(_ node: CodeBlockSyntax) {
        variableDeclScopes.pop()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.push(.likeStruct(node.identifier.text))
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
            if node.name.tokenKind == .keyword(.self) {
                return .skipChildren
            }
        }
        return .visitChildren
    }

    override func visitPost(_ node: IdentifierExprSyntax) {
        guard let parent = node.parent,
              !parent.is(SpecializeExprSyntax.self),
              !parent.is(DictionaryElementSyntax.self),
              !parent.is(ArrayElementSyntax.self) else {
            return
        }
        if parent.is(FunctionCallExprSyntax.self), case .likeClass = parentDeclScopes.peek() {
            return
        }
        addViolation(on: node.identifier)
    }

    override func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
        if case .likeClass = parentDeclScopes.peek() {
            variableDeclScopes.push(.skipReferences)
        } else {
            variableDeclScopes.push(.handleReferences)
        }
        return .visitChildren
    }

    override func visitPost(_ node: MemberDeclBlockSyntax) {
        variableDeclScopes.pop()
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        if case .likeClass = parentDeclScopes.peek(), case .identifier("selector") = node.macro.tokenKind {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
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

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.push(.likeStruct(node.identifier.text))
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        parentDeclScopes.pop()
    }

    override func visitPost(_ node: SimpleTypeIdentifierSyntax) {
        guard let parent = node.parent else {
            return
        }
        if case .likeClass = parentDeclScopes.peek(),
           parent.is(GenericArgumentSyntax.self) || parent.is(ReturnClauseSyntax.self) {
            // Type is a generic parameter or the return type of a function.
            return
        }
        if node.genericArguments == nil {
            // Type is specialized.
            addViolation(on: node.name)
        }
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
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
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true || varDecl.bindings.onlyElement?.accessor != nil {
                // Is either a local variable declaration or a computed property.
                return .visitChildren
            }
        }
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.bindings.onlyElement?.accessor != nil {
            // Variable declaration is a computed property.
            return .visitChildren
        }
        if case .handleReferences = variableDeclScopes.peek() {
            return .visitChildren
        }
        return .skipChildren
    }

    private func addViolation(on node: TokenSyntax) {
        if let parentName = parentDeclScopes.peek()?.parentName, node.tokenKind == .identifier(parentName) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
            corrections.append(
                (start: node.positionAfterSkippingLeadingTrivia, end: node.endPositionBeforeTrailingTrivia)
            )
        }
    }
}
