import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyFunctionBodyRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_empty_function_body",
        name: "No Empty Function Body",
        description: "Function bodies should not be empty; they should at least contain a comment",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
                func f() {
                    let a = 1
                }
                """),
            Example("""
                func f() {
                    // comment
                }
                """),
            Example("""
                init() { /* comment */ }
            """),
            Example("""
                deinit { /* comment */ }
            """)
        ],
        triggeringExamples: [
            Example("""
                func f() ↓{
                }
            """),
            Example("""
                // comment
                func f() ↓{}
            """),
            Example("""
                init() ↓{}
            """),
            Example("""
                deinit ↓{}
            """)
        ]
    )
}

private extension NoEmptyFunctionBodyRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            validateBody(node.body)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            validateBody(node.body)
        }

        override func visitPost(_ node: DeinitializerDeclSyntax) {
            validateBody(node.body)
        }

        func validateBody(_ node: CodeBlockSyntax?) {
            guard let node,
                  node.statements.isEmpty,
                  !node.leftBrace.trailingTrivia.containsComments,
                  !node.rightBrace.leadingTrivia.containsComments else {
                return
            }

            violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
        }
    }
}
