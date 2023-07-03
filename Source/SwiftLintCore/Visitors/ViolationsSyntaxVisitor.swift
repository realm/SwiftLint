import SwiftSyntax

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
open class ViolationsSyntaxVisitor: SyntaxVisitor {
    /// Positions in a source file where violations should be reported.
    public var violations: [ReasonedRuleViolation] = []
    /// List of declaration types that shall be skipped while traversing the AST.
    open var skippableDeclarations: [DeclSyntaxProtocol.Type] { [] }

    override open func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == ActorDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == ClassDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == EnumDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == ExtensionDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == FunctionDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == FunctionDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == VariableDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == ProtocolDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == StructDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == InitializerDeclSyntax.self } ? .skipChildren : .visitChildren
    }
}

public extension Array where Element == DeclSyntaxProtocol.Type {
    /// All visitable declaration syntax types.
    static let all: Self = [
        ActorDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        FunctionDeclSyntax.self,
        ExtensionDeclSyntax.self,
        ProtocolDeclSyntax.self,
        StructDeclSyntax.self,
        VariableDeclSyntax.self
    ]

    /// Useful for class-specific checks since extensions and protocols do not allow nested classes.
    static let extensionsAndProtocols: Self = [
        ExtensionDeclSyntax.self,
        ProtocolDeclSyntax.self
    ]

    /// All declarations except for the specified ones.
    ///
    /// - parameter declarations: The declarations to exclude from all declarations.
    ///
    /// - returns: All declarations except for the specified ones.
    static func allExcept(_ declarations: Element...) -> Self {
        all.filter { decl in !declarations.contains { $0 == decl } }
    }
}
