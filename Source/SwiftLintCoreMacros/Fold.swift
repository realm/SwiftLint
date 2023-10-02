import SwiftSyntax
import SwiftSyntaxMacros

struct Fold: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [
            try ExtensionDeclSyntax("""
                extension \(type) {
                    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                        file.foldedSyntaxTree
                    }
                }
                """)
        ]
    }
}
