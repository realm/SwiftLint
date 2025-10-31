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
        ].compactMap(\.self)
    }
}

private extension AttributeSyntax {
    func foldArgument(_ context: some MacroExpansionContext) -> Bool {
        isArgumentTrue(withName: "foldExpressions", in: context)
    }

    func explicitRewriterArgument(_ context: some MacroExpansionContext) -> Bool {
        isArgumentTrue(withName: "explicitRewriter", in: context)
    }

    func correctableArgument(_ context: some MacroExpansionContext) -> Bool {
        isArgumentTrue(withName: "correctable", in: context)
    }

    func optInArgument(_ context: some MacroExpansionContext) -> Bool {
        isArgumentTrue(withName: "optIn", in: context)
    }
}

private extension Bool {
    func ifTrue<P: SyntaxProtocol>(_ result: @autoclosure () throws -> P) rethrows -> P? {
        self ? try result() : nil
    }
}
