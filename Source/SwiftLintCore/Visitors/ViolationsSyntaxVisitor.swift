import SwiftSyntax

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
open class ViolationsSyntaxVisitor<Configuration: RuleConfiguration>: SyntaxVisitor {
    /// A rule's configuration.
    public let configuration: Configuration
    /// The file from which the traversed syntax tree stems from.
    public let file: SwiftLintFile

    /// A source location converter associated with the syntax tree being traversed.
    public lazy var locationConverter = file.locationConverter

    /// Initializer for a ``ViolationsSyntaxVisitor``.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    @inlinable
    public init(configuration: Configuration, file: SwiftLintFile) {
        self.configuration = configuration
        self.file = file
        super.init(viewMode: .sourceAccurate)
    }

    /// Positions in a source file where violations should be reported.
    public var violations: [ReasonedRuleViolation] = []

    /// List of declaration types that shall be skipped while traversing the AST.
    open var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [] }

    override open func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    override open func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    private func shallSkip(_ node: some DeclSyntaxProtocol) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == node.syntaxNodeType } ? .skipChildren : .visitChildren
    }
}

public extension Array where Element == any DeclSyntaxProtocol.Type {
    /// All visitable declaration syntax types.
    static let all: Self = [
        ActorDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        ExtensionDeclSyntax.self,
        FunctionDeclSyntax.self,
        InitializerDeclSyntax.self,
        ProtocolDeclSyntax.self,
        StructDeclSyntax.self,
        SubscriptDeclSyntax.self,
        VariableDeclSyntax.self,
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
