import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum SwiftSyntaxRule: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
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
            try node.foldArgument(context).ifTrue(
                try ExtensionDeclSyntax("""
                    extension \(type) {
                        func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                            file.foldedSyntaxTree
                        }
                    }
                    """
                )
            ),
            try node.explicitRewriterArgument(context).ifTrue(
                try ExtensionDeclSyntax("""
                    extension \(type): SwiftSyntaxCorrectableRule {
                        func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter<ConfigurationType>? {
                            Rewriter(configuration: configuration, file: file)
                        }
                    }
                    """
                )
            ),
            try (node.correctableArgument(context) && !node.explicitRewriterArgument(context)).ifTrue(
                try ExtensionDeclSyntax("""
                    extension \(type): SwiftSyntaxCorrectableRule {}
                    """
                )
            ),
            try node.optInArgument(context).ifTrue(
                try ExtensionDeclSyntax("""
                    extension \(type): OptInRule {}
                    """
                )
            ),
        ].compactMap { $0 }
    }
}

private extension AttributeSyntax {
    func foldArgument(_ context: some MacroExpansionContext) -> Bool {
        findArgument(withName: "foldExpressions", in: context)
    }

    func explicitRewriterArgument(_ context: some MacroExpansionContext) -> Bool {
        findArgument(withName: "explicitRewriter", in: context)
    }

    func correctableArgument(_ context: some MacroExpansionContext) -> Bool {
        findArgument(withName: "correctable", in: context)
    }

    func optInArgument(_ context: some MacroExpansionContext) -> Bool {
        findArgument(withName: "optIn", in: context)
    }

    private func findArgument(withName name: String, in context: some MacroExpansionContext) -> Bool {
        if case let .argumentList(args) = arguments, let first = args.first(where: { $0.label?.text == name }) {
            let expr = first.expression
            if expr.isBooleanLiteral {
                return expr.isTrueLiteral
            }
            context.diagnose(SwiftLintCoreMacroError.noBooleanLiteral.diagnose(at: expr))
        }
        return false
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

private extension Bool {
    func ifTrue<P: SyntaxProtocol>(_ result: @autoclosure () throws -> P) rethrows -> P? {
        self ? try result() : nil
    }
}
