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
    /// Ranges of violations to be used in rewriting (see ``SwiftSyntaxCorrectableRule``). It is not mandatory to fill
    /// this list while traversing the AST, especially not if the rule is not correctable or provides a custom rewriter.
    public var violationCorrections = [ViolationCorrection]()

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

    override open func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind { shallSkip(node) }

    private func shallSkip(_ node: some DeclSyntaxProtocol) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == node.syntaxNodeType } ? .skipChildren : .visitChildren
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
