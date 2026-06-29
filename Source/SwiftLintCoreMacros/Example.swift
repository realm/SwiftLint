import SwiftBasicFormat
import SwiftLintBase
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable fatal_error

struct Example: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let fileID = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .fileID),
              let filePath = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath) else {
            context.diagnose(SwiftLintCoreMacroError.invalidSourceLocation.diagnose(at: node))
            fatalError(SwiftLintCoreMacroError.invalidSourceLocation.message)
        }

        guard let trailingClosure = node.trailingClosure else {
            context.diagnose(SwiftLintCoreMacroError.missingExampleBody.diagnose(at: node))
            fatalError(SwiftLintCoreMacroError.missingExampleBody.message)
        }

        let spacesCount = trailingClosure.rightBrace.leadingTrivia.countSpaces
        let example = """
            Example(
                code: \"\"\"\(trailingClosure.statements.asExampleBody(unindentedBy: spacesCount))
                \"\"\",
                \(node.exampleArguments),
                fileID: \(fileID.file),
                file: \(filePath.file),
                line: \(filePath.line)
            )
            """.indent(by: spacesCount)
        return ExprSyntax(stringLiteral: example)
    }
}

private extension FreestandingMacroExpansionSyntax {
    func argumentValue(named name: String) -> String? {
        arguments.first { $0.label?.text == name }?.expression.description
    }

    var exampleArguments: String {
        """
        configuration: \(argumentValue(named: "configuration") ?? "[:]"),
        testMultiByteOffsets: \(argumentValue(named: "testMultiByteOffsets") ?? "true"),
        testWrappingInComment: \(argumentValue(named: "testWrappingInComment") ?? "true"),
        testWrappingInString: \(argumentValue(named: "testWrappingInString") ?? "true"),
        testDisableCommand: \(argumentValue(named: "testDisableCommand") ?? "true"),
        testOnLinux: \(argumentValue(named: "testOnLinux") ?? "true"),
        testOnWindows: \(argumentValue(named: "testOnWindows") ?? "true"),
        excludeFromDocumentation: \(argumentValue(named: "excludeFromDocumentation") ?? "false")
        """.indent(by: 4, skipFirst: true)
    }
}

private extension CodeBlockItemListSyntax {
    func asExampleBody(unindentedBy spaces: Int) -> String {
        CodeIndentingRewriter(style: .unindentSpaces(spaces))
            .visit(self)
            .description
            .replacing("/*>*/", with: "↓")
    }
}

private extension Trivia {
    var countSpaces: Int {
        pieces.compactMap { piece in
            switch piece {
            case let .spaces(number): number
            default: nil
            }
        }.reduce(0, +)
    }
}
