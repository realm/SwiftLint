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
        let bodyArgument = node.arguments.first { $0.label?.text == "body" }
        if let closureArgument = bodyArgument?.expression.as(ClosureExprSyntax.self) {
            guard node.trailingClosure == nil else {
                context.diagnose(SwiftLintCoreMacroError.tooManyArguments.diagnose(at: node))
                fatalError(SwiftLintCoreMacroError.tooManyArguments.message)
            }
            let body = closureArgument.statements
                .with(\.leadingTrivia, node.leadingTrivia)
                .description
                .replacing("/*>*/", with: "↓")
            return """
                Example(
                    \"\"\"
                    \(raw: body)
                    \"\"\",
                    \(raw: node.exampleArguments),
                    fileID: \(raw: fileID.file),
                    file: \(raw: filePath.file),
                    line: \(raw: filePath.line)
                )
                """
        }
        guard let trailingClosure = node.trailingClosure else {
            context.diagnose(SwiftLintCoreMacroError.missingExampleBody.diagnose(at: node))
            fatalError(SwiftLintCoreMacroError.missingExampleBody.message)
        }
        let body = trailingClosure.statements
            .with(\.leadingTrivia, node.leadingTrivia)
            .description
            .replacing("/*>*/", with: "↓")
        return """
            Example(
                \"\"\"
                \(raw: body)
                \"\"\",
                \(raw: node.exampleArguments),
                fileID: \(raw: fileID.file),
                file: \(raw: filePath.file),
                line: \(raw: filePath.line)
            )
            """
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
        """
    }
}
