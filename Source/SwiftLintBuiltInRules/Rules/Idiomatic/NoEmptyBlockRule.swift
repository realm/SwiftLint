import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct NoEmptyBlockRule: OptInRule {
    var configuration = NoEmptyBlockConfiguration()

    static let description = RuleDescription(
        identifier: "no_empty_block",
        name: "No Empty Block",
        description: "Code blocks should contain at least one statement or comment",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func f() {
                /* do something */
            }

            var flag = true {
                willSet { /* do something */ }
            }
            """),

            Example("""
            class Apple {
                init() { /* do something */ }

                deinit { /* do something */ }
            }
            """),

            Example("""
            for _ in 0..<10 { /* do something */ }

            do {
                /* do something */
            } catch {
                /* do something */
            }

            defer {
                /* do something */
            }

            if flag {
                /* do something */
            } else {
                /* do something */
            }

            repeat { /* do something */ } while (flag)

            while i < 10 { /* do something */ }
            """),

            Example("""
            func f() {}

            var flag = true {
                willSet {}
            }
            """, configuration: ["disabled_block_types": ["function_bodies"]]),

            Example("""
            class Apple {
                init() {}

                deinit {}
            }
            """, configuration: ["disabled_block_types": ["initializer_bodies"]]),

            Example("""
            for _ in 0..<10 {}

            do {
            } catch {
            }

            defer {}

            if flag {
            } else {
            }

            repeat {} while (flag)

            while i < 10 {}
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
        ],
        triggeringExamples: [
            Example("""
            func f() ↓{}

            var flag = true {
                willSet ↓{}
            }
            """),

            Example("""
            class Apple {
                init() ↓{}

                deinit ↓{}
            }
            """),

            Example("""
            for _ in 0..<10 ↓{}

            do ↓{
            } catch ↓{
            }

            defer ↓{}

            if flag ↓{
            } else ↓{
            }

            repeat ↓{} while (flag)

            while i < 10 ↓{}
            """),
        ]
    )
}

private extension NoEmptyBlockRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: CodeBlockSyntax) {
            if let codeBlockType = node.codeBlockType, configuration.enabledBlockTypes.contains(codeBlockType) {
                validate(node: node)
            }
        }

        func validate(node: CodeBlockSyntax) {
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
        case .guardStmt:
            // No need to handle this case since Empty Block of `guard` is compile error.
            nil
        default:
            nil
        }
    }
}
