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
            // No need to show a warning since Empty Block of `guard` is compile error.
            guard node.parent?.kind != .guardStmt else { return }

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
        switch kind {
        case .accessorDecl:
            return .accessorBodies
        case .functionDecl:
            return .functionBodies
        case .initializerDecl, .deinitializerDecl:
            return .initializerBodies
        case .forStmt, .doStmt, .whileStmt, .repeatStmt, .ifExpr, .guardStmt, .catchClause, .deferStmt:
            return .statementBlocks
        default:
            return nil
        }
    }
}
