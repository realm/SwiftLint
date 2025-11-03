import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

#if os(macOS)
private let pathPrefix = "/private"
#else
private let pathPrefix = ""
#endif

enum TemporaryDirectory: BodyMacro {
    static func expansion(of _: AttributeSyntax,
                          providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
                          in context: some MacroExpansionContext) -> [CodeBlockItemSyntax] {
        guard let body = declaration.body else {
            context.diagnose(SwiftLintCoreMacroError.noBody.diagnose(at: declaration))
            return []
        }
        return [
            """
            let _currentDirectory = FileManager.default.currentDirectoryPath
            FileManager.default.changeCurrentDirectoryPath(
                "\(raw: pathPrefix)" + FileManager.default.temporaryDirectory.path
            )
            defer { FileManager.default.changeCurrentDirectoryPath(_currentDirectory) }
            """,
        ] + Array(body.statements)
    }
}
