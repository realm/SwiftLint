import SwiftSyntax

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
open class ViolationsSyntaxVisitor: SyntaxVisitor {
    /// Positions in a source file where violations should be reported.
    public var violations: [ReasonedRuleViolation] = []
    /// Ranges of violations to be used in rewriting (see ``SwiftSyntaxCorrectableRule``). It is not mandatory to fill
    /// this list while traversing the AST, especially not if the rule is not correctable or provides a custom rewriter.
    public var violationCorrections = [ViolationCorrection]()

    /// List of declaration types that shall be skipped while traversing the AST.
    open var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [] }

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

/// The correction of a violation that is basically the violation's range in the source code and a
/// replacement for this range that would fix the violation.
public struct ViolationCorrection {
    /// Start position of the violation range.
    public let start: AbsolutePosition
    /// End position of the violation range.
    let end: AbsolutePosition
    /// Replacement for the violating range.
    let replacement: String

    /// Create a ``ViolationCorrection``.
    /// - Parameters:
    ///   - start:          Start position of the violation range.
    ///   - end:            End position of the violation range.
    ///   - replacement:    Replacement for the violating range.
    public init(start: AbsolutePosition, end: AbsolutePosition, replacement: String) {
        self.start = start
        self.end = end
        self.replacement = replacement
    }
}

public extension Array where Element == any DeclSyntaxProtocol.Type {
    /// All visitable declaration syntax types.
    static let all: Self = [
        ActorDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        FunctionDeclSyntax.self,
        ExtensionDeclSyntax.self,
        InitializerDeclSyntax.self,
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
