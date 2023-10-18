import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum SwiftSyntaxRule: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [
            try ExtensionDeclSyntax("""
                extension \(type): SwiftSyntaxRule {
                    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                        Visitor(configuration: configuration, file: file)
                    }
                }
                """
            ),
            try makeExtension(dependingOn: node.foldArgument, in: context, with: """
                extension \(type) {
                    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                        file.foldedSyntaxTree
                    }
                }
                """
            ),
            try makeExtension(dependingOn: node.explicitRewriterArgument, in: context, with: """
                extension \(type): SwiftSyntaxCorrectableRule {
                    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
                        Rewriter(
                            locationConverter: file.locationConverter,
                            disabledRegions: disabledRegions(file: file)
                        )
                    }
                }
                """
            )
        ].compactMap { $0 }
    }

    private static func makeExtension(
        dependingOn argument: ExprSyntax?,
        in context: some MacroExpansionContext,
        with content: SyntaxNodeString
    ) throws -> ExtensionDeclSyntax? {
        if let argument {
            if argument.isBooleanLiteral {
                if argument.isTrueLiteral {
                    return try ExtensionDeclSyntax(content)
                }
            } else {
                context.diagnose(SwiftLintCoreMacroError.noBooleanLiteral.diagnose(at: argument))
            }
        }
        return nil
    }
}

private extension AttributeSyntax {
    var foldArgument: ExprSyntax? {
        findArgument(withName: "foldExpressions")
    }

    var explicitRewriterArgument: ExprSyntax? {
        findArgument(withName: "explicitRewriter")
    }

    private func findArgument(withName name: String) -> ExprSyntax? {
        if case let .argumentList(args) = arguments, let first = args.first(where: { $0.label?.text == name }) {
            first.expression
        } else {
            nil
        }
    }
}

private extension ExprSyntax {
    var isBooleanLiteral: Bool {
        `is`(BooleanLiteralExprSyntax.self)
    }

    var isTrueLiteral: Bool {
        `as`(BooleanLiteralExprSyntax.self)?.literal.text == "true"
    }
}
