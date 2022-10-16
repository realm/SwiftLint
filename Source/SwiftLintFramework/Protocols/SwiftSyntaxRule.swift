import SwiftSyntax

/// A SwiftLint Rule backed by SwiftSyntax that does not use SourceKit requests.
public protocol SwiftSyntaxRule: SourceKitFreeRule {
    /// Produce a `ViolationsSyntaxVisitor` for the given file.
    ///
    /// - parameter file: The file for which to produce the visitor.
    ///
    /// - returns: A `ViolationsSyntaxVisitor` for the given file.
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor?

    /// Produce a violation for the given file and absolute position.
    ///
    /// - parameter file:     The file for which to produce the violation.
    /// - parameter position: The absolute position in the file where the violation should be located.
    ///
    /// - returns: A violation for the given file and absolute position.
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation

    /// Gives a chance for the rule to do some pre-processing on the syntax tree.
    /// One typical example is using `SwiftOperators` to "fold" the tree, resolving operators precedence.
    /// By default, it just returns the same `syntaxTree`.
    ///
    /// - parameter syntaxTree: The syntax tree to run pre-processing on
    ///
    /// - returns: The tree that will be used to check for violations. If `nil`, this rule will return no violations.
    func preprocess(syntaxTree: SourceFileSyntax) -> SourceFileSyntax?
}

public extension SwiftSyntaxRule where Self: ConfigurationProviderRule,
                                       ConfigurationType: SeverityBasedRuleConfiguration {
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, position: position)
        )
    }
}

public extension SwiftSyntaxRule {
    /// Returns the source ranges in the specified file where this rule is disabled.
    ///
    /// - parameter file: The file to get regions.
    ///
    /// - returns: The source ranges in the specified file where this rule is disabled.
    func disabledRegions(file: SwiftLintFile) -> [SourceRange] {
        let locationConverter = file.locationConverter
        return file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let visitor = makeVisitor(file: file),
              let syntaxTree = preprocess(syntaxTree: file.syntaxTree) else {
            return []
        }

        return visitor
            .walk(tree: syntaxTree, handler: \.violationPositions)
            .sorted()
            .map { makeViolation(file: file, position: $0) }
    }

    func preprocess(syntaxTree: SourceFileSyntax) -> SourceFileSyntax? {
        syntaxTree
    }
}

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
open class ViolationsSyntaxVisitor: SyntaxVisitor {
    /// Positions in a source file where violations should be reported.
    internal var violationPositions: [AbsolutePosition] = []
    /// List of declaration types that shall be skipped while traversing the AST.
    internal var skippableDeclarations: [DeclSyntaxProtocol.Type] { [] }

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

    override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == ProtocolDeclSyntax.self } ? .skipChildren : .visitChildren
    }

    override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        skippableDeclarations.contains { $0 == StructDeclSyntax.self } ? .skipChildren : .visitChildren
    }
}

extension Array where Element == DeclSyntaxProtocol.Type {
    static let all: Self = [
        ActorDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        FunctionDeclSyntax.self,
        ExtensionDeclSyntax.self,
        ProtocolDeclSyntax.self,
        StructDeclSyntax.self
    ]

    /// Useful for class-specific checks since extensions and protocols do not allow nested classes.
    static let extensionsAndProtocols: Self = [
        ExtensionDeclSyntax.self,
        ProtocolDeclSyntax.self
    ]

    static func allExcept(_ declarations: Element...) -> Self {
        all.filter { decl in !declarations.contains { $0 == decl } }
    }
}
