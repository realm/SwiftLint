import SwiftSyntax
import SwiftSyntaxMacros

struct SwiftSyntaxRule: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [
            try ExtensionDeclSyntax("""
                extension \(type): SwiftSyntaxRule {
                    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                        Visitor(configuration: configuration, file: file)
                    }
                }
                """),
            try createFoldingPreprocessor(type: type, foldArgument: node.foldArgument),
            try createRewriter(type: type, rewriterArgument: node.explicitRewriterArgument)
        ].compactMap { $0 }
    }

    private static func createFoldingPreprocessor(
        type: some TypeSyntaxProtocol,
        foldArgument: ExprSyntax?
    ) throws -> ExtensionDeclSyntax? {
        guard foldArgument.isTrueLiteral else {
            return nil
        }
        return try ExtensionDeclSyntax("""
            extension \(type) {
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }
            """)
    }

    private static func createRewriter(
        type: some TypeSyntaxProtocol,
        rewriterArgument: ExprSyntax?
    ) throws -> ExtensionDeclSyntax? {
        guard rewriterArgument.isTrueLiteral else {
            return nil
        }
        return try ExtensionDeclSyntax("""
            extension \(type): SwiftSyntaxCorrectableRule {
                func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
                    Rewriter(locationConverter: file.locationConverter, disabledRegions: disabledRegions(file: file))
                }
            }
            """)
    }
}

private extension AttributeSyntax {
    var foldArgument: ExprSyntax? {
        findArgument(withName: "foldExpressions")
    }

    var explicitRewriterArgument: ExprSyntax? {
        findArgument(withName: "explicitRewriter")
    }

    private func findArgument(withName name: String) -> ExprSyntax? {
        if case let .argumentList(args) = arguments, let first = args.first(where: { $0.label?.text == name }) {
            first.expression
        } else {
            nil
        }
    }
}

private extension ExprSyntax? {
    var isTrueLiteral: Bool {
        self?.as(BooleanLiteralExprSyntax.self)?.literal.text == "true"
    }
}
