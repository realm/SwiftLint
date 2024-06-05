import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyFunctionRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_empty_function",
        name: "No Empty Function",
        description: "Init/Deinit/Function body should not be empty, add comment to explain why it's empty",
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

private extension NoEmptyFunctionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else { return }
            if let violation = validateBody(body) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else { return }
            if let violation = validateBody(body) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: DeinitializerDeclSyntax) {
            guard let body = node.body else { return }
            if let violation = validateBody(body) {
                violations.append(violation)
            }
        }

        func validateBody(_ node: CodeBlockSyntax) -> ReasonedRuleViolation? {
            guard node.statements.isEmpty,
                  !node.leftBrace.trailingTrivia.containsComments,
                  !node.rightBrace.leadingTrivia.containsComments else {
                return nil
            }

            return ReasonedRuleViolation(
                position: node.leftBrace.positionAfterSkippingLeadingTrivia,
                reason: "Init/Deinit/Function body should not be empty, add comment to explain why it's empty",
                severity: .warning
            )
        }
    }
}
