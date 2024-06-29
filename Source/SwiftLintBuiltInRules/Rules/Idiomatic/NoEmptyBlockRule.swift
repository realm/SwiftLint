import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyBlockRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_empty_block",
        name: "No Empty Block",
        description: "Code blocks should not be empty; they should at least contain a comment",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            var flag = true {
                willSet { /* do something */ }
            }
            """),
            Example("""
            do {
                /* do something */
            } catch {
                /* do something */
            }
            """),
            Example("""
            defer {
                /* do something */
            }
            """),
            Example("""
            deinit { /* do something */ }
            """),
            Example("""
            for _ in 0..<10 { /* do something */ }
            """),
            Example("""
            func f() {
                /* do something */
            }
            """),
            Example("""
            if flag {
                /* do something */
            } else {
                /* do something */
            }
            """),
            Example("""
            init() { /* do something */ }
            """),
            Example("""
            repeat { /* do something */ } while (flag)
            """),
            Example("""
            while i < 10 { /* do something */ }
            """)
        ],
        triggeringExamples: [
            Example("""
            var flag = true {
                willSet ↓{}
            }
            """),
            Example("""
            do ↓{
            } catch ↓{
            }
            """),
            Example("""
            defer ↓{}
            """),
            Example("""
            deinit ↓{}
            """),
            Example("""
            for _ in 0..<10 ↓{}
            """),
            Example("""
            func f() ↓{}
            """),
            Example("""
            if flag ↓{
            } else ↓{
            }
            """),
            Example("""
            init() ↓{}
            """),
            Example("""
            repeat ↓{} while (flag)
            """),
            Example("""
            while i < 10 ↓{}
            """)
        ]
    )
}

private extension NoEmptyBlockRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: CodeBlockSyntax) {
            // No need to show a warning since Empty Block of `guard` is compile error.
            guard node.parent?.kind != .guardStmt else { return }

            guard node.statements.isEmpty,
                  !node.leftBrace.trailingTrivia.containsComments,
                  !node.rightBrace.leadingTrivia.containsComments else {
                return
            }

            violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
        }
    }
}
