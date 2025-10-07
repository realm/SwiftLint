import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum WorkingDirectory: BodyMacro {
    static func expansion(
        of attributes: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let body = declaration.body else {
            context.diagnose(SwiftLintCoreMacroError.noBody.diagnose(at: declaration))
            return []
        }
        guard let path = attributes.argument(withName: "path") else {
            context.diagnose(SwiftLintCoreMacroError.missingPathArgument.diagnose(at: attributes))
            return []
        }
        return [
            """
            let _currentDirectory = FileManager.default.currentDirectoryPath
            FileManager.default.changeCurrentDirectoryPath(\(path))
            defer { FileManager.default.changeCurrentDirectoryPath(_currentDirectory) }
            """,
        ] + Array(body.statements)
    }
}
