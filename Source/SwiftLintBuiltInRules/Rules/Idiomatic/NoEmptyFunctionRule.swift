import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyFunctionRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_empty_function",
        name: "No Empty Function",
        description: "Function body should not be empty, please add comment to explain why it's empty",
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
                func f() { // coment
                }
                """)
        ],
        triggeringExamples: [
            Example("""
                func f() ↓{}
            """),
            Example("""
                func f() ↓{
                }
            """),
            Example("""
                // comment
                func f() ↓{}
            """)
        ]
    )
}

private extension NoEmptyFunctionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body,
                  body.statements.isEmpty else {
                return
            }

            guard !body.leftBrace.trailingTrivia.containsComments,
                  !body.rightBrace.leadingTrivia.containsComments else {
                return
            }

            let violation = ReasonedRuleViolation(
                position: body.leftBrace.positionAfterSkippingLeadingTrivia,
                reason: "Function body should not be empty, please add comment to explain why it's empty",
                severity: .warning
            )
            violations.append(violation)
        }
    }
}
