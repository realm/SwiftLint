import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyBlockRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_empty_block",
        name: "No Empty Block",
        // swiftlint:disable:next line_length
        description: "Code Blocks(Function bodies, catch, defer) should not be empty; they should at least contain a comment",
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
            """),
            Example("""
            defer {
                /* comment */
            }
            """),
            Example("""
            do {
            } catch {
                /* comment */
            }
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
            """),
            Example("""
            defer ↓{
            }
            """),
            Example("""
            do {
                // some codes
            } catch ↓{
            }
            """)
        ]
    )
}

private extension NoEmptyBlockRule {
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

        override func visitPost(_ node: DeferStmtSyntax) {
            validateBody(node.body)
        }

        override func visitPost(_ node: CatchClauseSyntax) {
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
