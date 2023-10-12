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
            try createFoldingPreprocessor(type: type, foldArgument: node.foldArgument)
        ].compactMap { $0 }
    }

    private static func createFoldingPreprocessor(
        type: some TypeSyntaxProtocol,
        foldArgument: ExprSyntax?
    ) throws -> ExtensionDeclSyntax? {
        guard
            let foldArgument,
            let booleanLiteral = foldArgument.as(BooleanLiteralExprSyntax.self)?.literal,
            booleanLiteral.text == "true"
        else {
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
}

private extension AttributeSyntax {
    var foldArgument: ExprSyntax? {
        if case let .argumentList(args) = arguments, let first = args.first, first.label?.text == "foldExpressions" {
            first.expression
        } else {
            nil
        }
    }
}
