import SwiftLintBase
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct Example: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let fileID = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .fileID),
              let filePath = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath) else {
            context.diagnose(SwiftLintCoreMacroError.invalidSourceLocation.diagnose(at: node))
            return ""
        }

        guard let trailingClosure = node.trailingClosure else {
            context.diagnose(SwiftLintCoreMacroError.missingExampleBody.diagnose(at: node))
            return ""
        }

        let spacesCount = trailingClosure.rightBrace.leadingTrivia.countSpaces
        let example: ExprSyntax = """
            Example(
                code: \"\"\"\(raw: trailingClosure.statements.asExampleBody(unindentedBy: spacesCount))
                \"\"\",\(raw: node.exampleArguments)
                fileID: \(fileID.file),
                file: \(filePath.file),
                line: \(filePath.line)
            )
            """
        return CodeIndentingRewriter(style: .indentSpaces(spacesCount)).visit(example)
    }
}

private extension FreestandingMacroExpansionSyntax {
    var exampleArguments: String {
        var arguments = [String]()
        if let configuration = argumentValue(named: "configuration") {
            arguments.append("configuration: \(configuration)")
        }
        if let testMultiByteOffsets = argumentValue(named: "testMultiByteOffsets") {
            arguments.append("testMultiByteOffsets: \(testMultiByteOffsets)")
        }
        if let testWrappingInComment = argumentValue(named: "testWrappingInComment") {
            arguments.append("testWrappingInComment: \(testWrappingInComment)")
        }
        if let testWrappingInString = argumentValue(named: "testWrappingInString") {
            arguments.append("testWrappingInString: \(testWrappingInString)")
        }
        if let testDisableCommand = argumentValue(named: "testDisableCommand") {
            arguments.append("testDisableCommand: \(testDisableCommand)")
        }
        if let testOnLinux = argumentValue(named: "testOnLinux") {
            arguments.append("testOnLinux: \(testOnLinux)")
        }
        if let testOnWindows = argumentValue(named: "testOnWindows") {
            arguments.append("testOnWindows: \(testOnWindows)")
        }
        if let excludeFromDocumentation = argumentValue(named: "excludeFromDocumentation") {
            arguments.append("excludeFromDocumentation: \(excludeFromDocumentation)")
        }
        if arguments.isEmpty {
            return ""
        }
        return "\n" + arguments
            .map { "    " + $0 }
            .joined(separator: ",\n") + ","
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
