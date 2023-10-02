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
                }
                """)
        ]
    }
}
