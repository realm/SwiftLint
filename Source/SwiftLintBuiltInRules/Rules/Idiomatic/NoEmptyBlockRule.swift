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
            """),
            Example("""
            var flag = true {
                willSet {}
            }
            """, configuration: ["disabled_block_types": ["function_bodies"]]),
            Example("""
            func f() {}
            """, configuration: ["disabled_block_types": ["function_bodies"]]),
            Example("""
            deinit {}
            """, configuration: ["disabled_block_types": ["initializer_bodies"]]),
            Example("""
            init() {}
            """, configuration: ["disabled_block_types": ["initializer_bodies"]]),
            Example("""
            for _ in 0..<10 {}
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
            Example("""
            do {
            } catch {
            }
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
            Example("""
            defer {}
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
            Example("""
            if flag {
            } else {
            }
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
            Example("""
            repeat {} while (flag)
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
            Example("""
            while i < 10 {}
            """, configuration: ["disabled_block_types": ["statement_blocks"]]),
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
        guard let kind = self.parent?.kind else { return nil }

        return switch kind {
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
