import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NoEmptyBlockRule: Rule {
    var configuration = NoEmptyBlockConfiguration()

    static let description = RuleDescription(
        identifier: "no_empty_block",
        name: "No Empty Block",
        description: "Code blocks should contain at least one statement or comment",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            func f() {
                /* do something */
            }

            var flag = true {
                willSet { /* do something */ }
            }
            """,

            """
            class Apple {
                init() { /* do something */ }

                deinit { /* do something */ }
            }
            """,

            """
            for _ in 0..<10 { /* do something */ }

            do {
                /* do something */
            } catch {
                /* do something */
            }

            func f() {
                defer {
                    /* do something */
                }
                print("other code")
            }

            if flag {
                /* do something */
            } else {
                /* do something */
            }

            repeat { /* do something */ } while (flag)

            while i < 10 { /* do something */ }
            """,

            """
            func f() {}

            var flag = true {
                willSet {}
            }
            """.configuration(["disabled_block_types": ["function_bodies"]]),

            """
            class Apple {
                init() {}

                deinit {}
            }
            """.configuration(["disabled_block_types": ["initializer_bodies"]]),

            """
            for _ in 0..<10 {}

            do {
            } catch {
            }

            func f() {
                defer {}
                print("other code")
            }

            if flag {
            } else {
            }

            repeat {} while (flag)

            while i < 10 {}
            """.configuration(["disabled_block_types": ["statement_blocks"]]),
            """
            f { _ in /* comment */ }
            f { _ in // comment
            }
            f { _ in
                // comment
            }
            """,
            """
            f {}
            {}()
            """.configuration(["disabled_block_types": ["closure_blocks"]]),
        ]),
        triggeringExamples: #examples([
            """
            func f() ↓{}

            var flag = true {
                willSet ↓{}
            }
            """,

            """
            class Apple {
                init() ↓{}

                deinit ↓{}
            }
            """,

            """
            for _ in 0..<10 ↓{}

            do ↓{
            } catch ↓{
            }

            func f() {
                defer ↓{}
                print("other code")
            }

            if flag ↓{
            } else ↓{
            }

            repeat ↓{} while (flag)

            while i < 10 ↓{}
            """,
            """
            f ↓{}
            """,
            """
            Button ↓{} label: ↓{}
            """,
        ])
    )
}

private extension NoEmptyBlockRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: CodeBlockSyntax) {
            if let codeBlockType = node.codeBlockType, configuration.enabledBlockTypes.contains(codeBlockType) {
                validate(node: node)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if configuration.enabledBlockTypes.contains(.closureBlocks),
               node.signature?.inKeyword.trailingTrivia.containsComments != true {
                validate(node: node)
            }
        }

        func validate(node: some BracedSyntax & WithStatementsSyntax) {
            guard node.statements.isEmpty,
                  !node.leftBrace.trailingTrivia.containsComments,
                  !node.rightBrace.leadingTrivia.containsComments else {
                return
            }
            violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension CodeBlockSyntax {
    var codeBlockType: NoEmptyBlockConfiguration.CodeBlockType? {
        switch parent?.kind {
        case .functionDecl, .accessorDecl:
            .functionBodies
        case .initializerDecl, .deinitializerDecl:
            .initializerBodies
        case .forStmt, .doStmt, .whileStmt, .repeatStmt, .ifExpr, .catchClause, .deferStmt:
            .statementBlocks
        case .closureExpr:
            .closureBlocks
        case .guardStmt:
            // No need to handle this case since Empty Block of `guard` is compile error.
            nil
        default:
            nil
        }
    }
}
