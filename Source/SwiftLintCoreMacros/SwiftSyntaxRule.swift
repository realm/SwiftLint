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
                    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
                        Visitor(viewMode: .sourceAccurate)
                    }
                    \(createFoldingPreprocessor(from: node.foldArgument))
                }
                """)
        ]
    }

    private static func createFoldingPreprocessor(from foldArgument: ExprSyntax?) -> DeclSyntax {
        guard let foldArgument else {
            return ""
        }
        if let booleanLiteral = foldArgument.as(BooleanLiteralExprSyntax.self)?.literal {
            if booleanLiteral.text == "true" {
                return """
                    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                        file.foldedSyntaxTree
                    }
                    """
            }
            if booleanLiteral.text == "false" {
                return ""
            }
        }
        return """
            func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                if \(foldArgument) { file.foldedSyntaxTree } else { nil }
            }
            """
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
