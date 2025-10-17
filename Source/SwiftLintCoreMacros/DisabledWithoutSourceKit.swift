import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DisabledWithoutSourceKit: ExtensionMacro {
    static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.notStruct.diagnose(at: declaration))
            return []
        }
        let acl = declaration.modifiers.first {
            ["public", "internal", "package", "fileprivate", "private"].contains($0.name.text)
        }?.name.text ?? "internal"
        let message = #"""
        "Skipping enabled rule '\(Self.identifier)' because it requires SourceKit and SourceKit access is prohibited."
        """#
        return [
            try ExtensionDeclSyntax("""
                \(raw: acl) extension \(type) {
                    private static let postMessage: Void = {
                        Issue.genericWarning(\(raw: message)).print()
                    }()

                    func notifyRuleDisabledOnce() {
                        _ = Self.postMessage
                    }
                }
                """),
        ]
    }
}
