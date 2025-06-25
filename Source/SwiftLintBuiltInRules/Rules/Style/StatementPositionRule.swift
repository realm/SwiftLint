import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct StatementPositionRule: Rule {
    var configuration = StatementPositionConfiguration()

    static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the same line, one space after the previous declaration",
        kind: .style,
        nonTriggeringExamples: StatementPositionRuleExamples.nonTriggeringExamples,
        triggeringExamples: StatementPositionRuleExamples.triggeringExamples,
        corrections: StatementPositionRuleExamples.corrections
    )

    static let uncuddledDescription = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the next line, with equal indentation to the " +
                     "previous declaration",
        kind: .style,
        nonTriggeringExamples: StatementPositionRuleExamples.uncuddledNonTriggeringExamples,
        triggeringExamples: StatementPositionRuleExamples.uncuddledTriggeringExamples,
        corrections: StatementPositionRuleExamples.uncuddledCorrections
    )
}

// MARK: - Shared Validation Logic

private struct StatementValidation {
    let hasLeadingNewline: Bool
    let hasTrailingContent: Bool
    let expectedIndentation: Int
    let actualIndentation: Int
    let isSingleSpace: Bool
    let hasCommentsBetween: Bool

    init(keyword: TokenSyntax, previousToken: TokenSyntax) {
        self.hasLeadingNewline = keyword.leadingTrivia.contains { piece in
            switch piece {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                return true
            default:
                return false
            }
        }
        self.hasTrailingContent = !previousToken.trailingTrivia.isEmpty
        self.expectedIndentation = Self.calculateIndentation(previousToken.leadingTrivia)
        self.actualIndentation = Self.calculateIndentation(keyword.leadingTrivia)
        self.isSingleSpace = previousToken.trailingTrivia.isSingleSpace

        // Check for comments between closing brace and keyword
        self.hasCommentsBetween = previousToken.trailingTrivia.contains(where: \.isComment) ||
                                  keyword.leadingTrivia.contains(where: \.isComment)
    }

    private static func calculateIndentation(_ trivia: Trivia) -> Int {
        var indentation = 0
        // Traverse the trivia in reverse because we need to calculate the indentation
        // of the *last* line in the trivia, not the first.
        for piece in trivia.reversed() {
            switch piece {
            case .spaces(let count):
                indentation += count
            case .tabs(let count):
                indentation += count * 4 // Assuming 1 tab = 4 spaces
            case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                break
            default:
                continue
            }
        }
        return indentation
    }

    func isValidForDefaultMode() -> Bool {
        !hasLeadingNewline && isSingleSpace
    }

    func isValidForUncuddledMode() -> Bool {
        hasLeadingNewline && !hasTrailingContent && actualIndentation == expectedIndentation
    }
}

// MARK: - Shared Helpers

private extension StatementPositionRule {
    static func validateAndPrepareCorrection(
        keyword: TokenSyntax,
        configuration: StatementPositionConfiguration
    ) -> (previousToken: TokenSyntax, validation: StatementValidation, needsCorrection: Bool)? {
        guard let previousToken = keyword.previousToken(viewMode: .sourceAccurate),
              previousToken.tokenKind == .rightBrace else { return nil }

        let validation = StatementValidation(keyword: keyword, previousToken: previousToken)
        let needsCorrection = configuration.statementMode == .default ?
            !validation.isValidForDefaultMode() :
            !validation.isValidForUncuddledMode()

        return (previousToken, validation, needsCorrection)
    }
}

// MARK: - Visitor

private extension StatementPositionRule {
    final class Visitor: ViolationsSyntaxVisitor<StatementPositionConfiguration> {
        override func visitPost(_ node: IfExprSyntax) {
            guard let elseKeyword = node.elseKeyword else { return }
            validateStatement(keyword: elseKeyword)
        }

        override func visitPost(_ node: DoStmtSyntax) {
            for catchClause in node.catchClauses {
                validateStatement(keyword: catchClause.catchKeyword)
            }
        }

        private func validateStatement(keyword: TokenSyntax) {
            guard let result = StatementPositionRule.validateAndPrepareCorrection(
                keyword: keyword,
                configuration: configuration
            ), result.needsCorrection else { return }

            let description = configuration.statementMode == .default ?
                StatementPositionRule.description :
                StatementPositionRule.uncuddledDescription

            violations.append(
                ReasonedRuleViolation(
                    position: keyword.positionAfterSkippingLeadingTrivia,
                    reason: description.description,
                    severity: configuration.severity
                )
            )
        }
    }
}

// MARK: - Rewriter

private extension StatementPositionRule {
    final class Rewriter: ViolationsSyntaxRewriter<StatementPositionConfiguration> {
        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard let elseKeyword = node.elseKeyword else {
                return super.visit(node)
            }

            if let corrected = correctIfStatement(node: node, elseKeyword: elseKeyword) {
                return super.visit(corrected)
            }

            return super.visit(node)
        }

        override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
            var newNode = node
            var newCatchClauses: [CatchClauseSyntax] = []
            var bodyUpdated = false

            for (index, catchClause) in node.catchClauses.enumerated() {
                if let corrected = correctCatchStatement(
                    catchClause: catchClause,
                    keyword: catchClause.catchKeyword
                ) {
                    newCatchClauses.append(corrected)

                    // Update the body's closing brace only for the first catch that needs correction
                    if !bodyUpdated && index == 0 {
                        var newBody = newNode.body
                        if configuration.statementMode == .default {
                            newBody.rightBrace = newBody.rightBrace.with(\.trailingTrivia, .space)
                        } else {
                            // Uncuddled mode - remove trailing trivia
                            newBody.rightBrace = newBody.rightBrace.with(\.trailingTrivia, [])
                        }
                        newNode.body = newBody
                        bodyUpdated = true
                    }
                } else {
                    newCatchClauses.append(catchClause)
                }
            }

            newNode.catchClauses = CatchClauseListSyntax(newCatchClauses)
            return super.visit(newNode)
        }

        private func correctIfStatement(node: IfExprSyntax, elseKeyword: TokenSyntax) -> IfExprSyntax? {
            guard let result = StatementPositionRule.validateAndPrepareCorrection(
                keyword: elseKeyword,
                configuration: configuration
            ), result.needsCorrection else { return nil }

            let validation = result.validation

            // Skip correction if there are comments between brace and keyword
            guard !validation.hasCommentsBetween else { return nil }

            numberOfCorrections += 1

            if configuration.statementMode == .default {
                // Update the right brace trailing trivia
                var newBody = node.body
                newBody.rightBrace = newBody.rightBrace.with(\.trailingTrivia, .space)
                let newNode = node.with(\.body, newBody)

                // Update the else keyword leading trivia
                return newNode.with(\.elseKeyword, elseKeyword.with(\.leadingTrivia, []))
            }
            // Uncuddled mode
            let newTrivia = Trivia.newline + .spaces(validation.expectedIndentation)

            // Update the right brace trailing trivia
            var newBody = node.body
            newBody.rightBrace = newBody.rightBrace.with(\.trailingTrivia, [])
            let newNode = node.with(\.body, newBody)

            // Update the else keyword leading trivia
            return newNode.with(\.elseKeyword, elseKeyword.with(\.leadingTrivia, newTrivia))
        }

        private func correctCatchStatement(catchClause: CatchClauseSyntax, keyword: TokenSyntax) -> CatchClauseSyntax? {
            guard let result = StatementPositionRule.validateAndPrepareCorrection(
                keyword: keyword,
                configuration: configuration
            ), result.needsCorrection else { return nil }

            let validation = result.validation

            // Skip correction if there are comments between brace and keyword
            guard !validation.hasCommentsBetween else { return nil }

            numberOfCorrections += 1

            if configuration.statementMode == .default {
                // For default mode, just update the keyword
                return catchClause.with(\.catchKeyword, keyword.with(\.leadingTrivia, []))
            }
            // Uncuddled mode
            let newTrivia = Trivia.newline + .spaces(validation.expectedIndentation)
            return catchClause.with(\.catchKeyword, keyword.with(\.leadingTrivia, newTrivia))
        }
    }
}
