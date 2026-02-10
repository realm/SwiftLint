import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ConditionalReturnsOnNewlineRule: Rule {
    var configuration = ConditionalReturnsOnNewlineConfiguration()

    static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        kind: .style,
        nonTriggeringExamples: [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example("""
            guard something
            else { return }
            """),
        ],
        triggeringExamples: [
            Example("↓guard true else { return }"),
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"),
            Example("""
            ↓guard condition else { XCTFail(); return }
            """),
        ],
        corrections: [
            Example("↓if true { return }"): Example("if true {\n    return\n}"),
            Example("↓if true { break } else { return }"): Example("if true { break } else {\n    return\n}"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"): Example("if true {\n    return \"YES\"\n} else { return \"NO\" }"),
        ]
    )
}

private extension ConditionalReturnsOnNewlineRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.ifKeyword) {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
                return
            }

            if let elseBody = node.elseBody?.as(CodeBlockSyntax.self), let elseKeyword = node.elseKeyword,
               isReturn(elseBody.statements.lastReturn, onTheSameLineAs: elseKeyword) {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if configuration.ifOnly {
                return
            }

            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.guardKeyword) {
                violations.append(node.guardKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isReturn(_ returnStmt: ReturnStmtSyntax?, onTheSameLineAs token: TokenSyntax) -> Bool {
            guard let returnStmt else {
                return false
            }

            return locationConverter.location(for: returnStmt.returnKeyword.positionAfterSkippingLeadingTrivia).line ==
                locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            // Match the visitor's logic: if body has violation, only fix body (and return early)
            // If body is fine, check else body
            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.ifKeyword) {
                numberOfCorrections += 1
                let modifiedNode = node.with(\.body, fixCodeBlock(node.body, baseToken: node.ifKeyword))
                return super.visit(modifiedNode)
            }

            // Check if else body's return is on the same line as the else keyword
            if let elseBody = node.elseBody?.as(CodeBlockSyntax.self), let elseKeyword = node.elseKeyword,
               isReturn(elseBody.statements.lastReturn, onTheSameLineAs: elseKeyword) {
                numberOfCorrections += 1
                let fixedElseBody = fixCodeBlock(elseBody, baseToken: node.ifKeyword)
                let modifiedNode = node.with(\.elseBody, .codeBlock(fixedElseBody))
                return super.visit(modifiedNode)
            }

            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            if configuration.ifOnly {
                return super.visit(node)
            }

            guard isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.guardKeyword) else {
                return super.visit(node)
            }

            numberOfCorrections += 1
            let fixedNode = node.with(\.body, fixCodeBlock(node.body, baseToken: node.guardKeyword))
            return super.visit(fixedNode)
        }

        private func isReturn(_ returnStmt: ReturnStmtSyntax?, onTheSameLineAs token: TokenSyntax) -> Bool {
            guard let returnStmt else {
                return false
            }

            return locationConverter.location(for: returnStmt.returnKeyword.positionAfterSkippingLeadingTrivia).line ==
                locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
        }

        private func fixCodeBlock(_ block: CodeBlockSyntax, baseToken: TokenSyntax) -> CodeBlockSyntax {
            // Get the indentation of the base token (e.g., `if` or `guard`)
            let baseIndentation = baseToken.leadingTrivia.indentation(isOnNewline: true) ?? Trivia()
            let innerIndentation = Trivia(pieces: baseIndentation.pieces + [.spaces(4)])

            // Check if the first statement is the return (i.e., return is the only statement)
            let returnIsFirst = block.statements.first?.item.is(ReturnStmtSyntax.self) == true

            // Fix the left brace: only remove trailing whitespace if return is the first statement
            let fixedLeftBrace = returnIsFirst
                ? block.leftBrace.with(\.trailingTrivia, Trivia())
                : block.leftBrace

            // Fix the statements: add newline + inner indentation before the return,
            // and remove trailing whitespace from the return value and the preceding statement
            var statements = Array(block.statements)
            for i in statements.indices {
                if statements[i].item.is(ReturnStmtSyntax.self) {
                    // Remove trailing whitespace from the previous statement if there is one
                    if i > 0 {
                        statements[i - 1] = statements[i - 1].with(\.trailingTrivia, Trivia())
                    }
                    // Add newline + indentation before return and remove its trailing whitespace
                    statements[i] = statements[i]
                        .with(
                            \.leadingTrivia,
                            Trivia(pieces: [.newlines(1)] + innerIndentation.pieces)
                        )
                        .with(\.trailingTrivia, Trivia())
                }
            }
            let fixedStatements = CodeBlockItemListSyntax(statements)

            // Fix the closing brace: add newline + base indentation before it
            let fixedRightBrace = block.rightBrace.with(
                \.leadingTrivia,
                Trivia(pieces: [.newlines(1)] + baseIndentation.pieces)
            )

            return block
                .with(\.leftBrace, fixedLeftBrace)
                .with(\.statements, fixedStatements)
                .with(\.rightBrace, fixedRightBrace)
        }
    }
}

private extension CodeBlockItemListSyntax {
    var lastReturn: ReturnStmtSyntax? {
        last?.item.as(ReturnStmtSyntax.self)
    }
}
