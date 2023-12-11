import SwiftSyntax

@SwiftSyntaxRule
struct RedundantExtensionRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_extension",
        name: "Redundant Extension",
        description: "Avoid redundant extensions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
                    extension Foo {
                        func something() {}
                    }
                    """),
            Example("""
                    extension Foo {
                        var a: Int { 1 }
                    }
                    """)
        ],
        triggeringExamples: [
            Example("""
                    ↓extension Bar {}
                    """)
        ]
    )
}

private extension RedundantExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var isRedundantExtension = false
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            return .allExcept(VariableDeclSyntax.self, FunctionDeclSyntax.self)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            isRedundantExtension = false
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            isRedundantExtension = false
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            isRedundantExtension = true
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            appendViolationIfNeeded(node: node.extensionKeyword)
        }

        func appendViolationIfNeeded(node: TokenSyntax) {
            if isRedundantExtension {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
