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
        var args = [String]()
        if node.needsLocationConverter {
            args.append("locationConverter: file.locationConverter")
        }

        if node.needsConfiguration {
            args.append("configuration: configuration")
        }

        if args.isEmpty {
            args.append("viewMode: .sourceAccurate")
        }

        let visitorExpr = "Visitor(\(args.joined(separator: ", ")))"
        let makeVisitorBody = if node.deprecated {
            """
            warnDeprecatedOnce()
            return \(visitorExpr)
            """
        } else {
            visitorExpr
        }
        return [
            try ExtensionDeclSyntax("""
                extension \(type): SwiftSyntaxRule {
                    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
                        \(raw: makeVisitorBody)
                    }
                }
                """),
            try createFoldingPreprocessor(type: type, foldArgument: node.foldExpressions)
        ].compactMap { $0 }
    }

    private static func createFoldingPreprocessor(
        type: some TypeSyntaxProtocol,
        foldArgument: Bool
    ) throws -> ExtensionDeclSyntax? {
        guard foldArgument else {
            return nil
        }

        return try ExtensionDeclSyntax("""
            extension \(type) {
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }
            """)
    }
}

private extension AttributeSyntax {
    var foldExpressions: Bool { hasTrueArgument(labeled: "foldExpressions") }
    var needsLocationConverter: Bool { hasTrueArgument(labeled: "needsLocationConverter") }
    var needsConfiguration: Bool { hasTrueArgument(labeled: "needsConfiguration") }
    var deprecated: Bool { hasTrueArgument(labeled: "deprecated") }

    func hasTrueArgument(labeled label: String) -> Bool {
        if
            case let .argumentList(args) = arguments,
            args.hasTrueArgument(labeled: label)
        {
            true
        } else {
            false
        }
    }
}

private extension LabeledExprListSyntax {
    func hasTrueArgument(labeled label: String) -> Bool {
        contains { arg in
            if
                arg.label?.text == label,
                let booleanLiteral = arg.expression.as(BooleanLiteralExprSyntax.self)?.literal,
                booleanLiteral.text == "true"
            {
                true
            } else {
                false
            }
        }
    }
}
