import SwiftSyntax

@SwiftSyntaxRule
struct StatementPositionRule: SwiftSyntaxCorrectableRule {
    var configuration = StatementPositionConfiguration()

    static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: """
            'else' and 'catch' keywords should be at a fixed position relative to the previous block.
        """,
        kind: .style,
        nonTriggeringExamples: StatementPositionRuleExamples.nonTriggeringExamples,
        triggeringExamples: StatementPositionRuleExamples.triggeringExamples,
        corrections: StatementPositionRuleExamples.corrections
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file),
            config: configuration
        )
    }
}

private extension StatementPositionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            switch configuration.statementMode {
            case .default:
                if let position = node.defaultModeViolationPosition()?.position {
                    violations.append(
                        ReasonedRuleViolation(
                            position: position,
                            reason: """
                                'else' should be on the same line, one space after the closing brace of \
                                the previous 'if' block
                            """,
                            severity: configuration.severity
                        )
                    )
                }
            case .uncuddledElse:
                if let position = node.uncuddledModeViolationPosition()?.position {
                    violations.append(
                        ReasonedRuleViolation(
                            position: position,
                            reason: """
                                'else' should be on the next line, with equal indentation to the previous 'if' keyword
                            """,
                            severity: configuration.severity
                        )
                    )
                }
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            switch configuration.statementMode {
            case .default:
                node.defaultModeViolationPositions()?.positions
                    .map {
                        ReasonedRuleViolation(
                            position: $0,
                            reason: """
                                'catch' should be on the same line, one space after the closing brace of \
                                the previous block
                            """,
                            severity: configuration.severity
                        )
                    }
                    .forEach { violations.append($0) }
            case .uncuddledElse:
                node.uncuddledModeViolationPositions()?.positions
                    .map {
                        ReasonedRuleViolation(
                            position: $0,
                            reason: """
                                'catch' should be on the next line, with equal indentation to the previous 'do' keyword
                            """,
                            severity: configuration.severity
                        )
                    }
                    .forEach { violations.append($0) }
            }
        }
    }
}

private extension StatementPositionRule {
    private class Rewriter: ViolationsSyntaxRewriter {
        private let config: ConfigurationType

        init(locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange],
             config: ConfigurationType) {
            self.config = config
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            let newNode: IfExprSyntax
            switch config.statementMode {
            case .default:
                guard
                    let (position, correctedNode) = node.defaultModeViolationPosition()
                else {
                    return super.visit(node)
                }

                correctionPositions.append(position)
                newNode = correctedNode
            case .uncuddledElse:
                guard
                    let (position, correctedNode) = node.uncuddledModeViolationPosition()
                else {
                    return super.visit(node)
                }

                correctionPositions.append(position)
                newNode = correctedNode
            }

            return super.visit(newNode)
        }

        override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
            var newNode = node

            switch config.statementMode {
            case .default:
                guard let (positions, correctedNode) = node.defaultModeViolationPositions()
                else {
                    return super.visit(node)
                }

                correctionPositions.append(contentsOf: positions)
                newNode = correctedNode
            case .uncuddledElse:
                guard let (positions, correctedNode) = node.uncuddledModeViolationPositions()
                else {
                    return super.visit(node)
                }

                correctionPositions.append(contentsOf: positions)
                newNode = correctedNode
            }

            return super.visit(newNode)
        }
    }
}

private extension IfExprSyntax {
    var elseBeforeIfKeyword: TokenSyntax? {
        if let previous = ifKeyword.previousToken(viewMode: .sourceAccurate), previous.isElseKeyword {
            return previous
        }
        return nil
    }

    func defaultModeViolationPosition() -> (position: AbsolutePosition, newNode: IfExprSyntax)? {
        // Check if the node has `else` keyword
        guard let elseKeyword else {
            return nil
        }

        let violationPosition: AbsolutePosition
        var newNode = self
        // Check if `else` doesn't have newline in leading trivia of `else`'and
        // multiple spaces in trailing trivia of `body`'s `rightBrace`
        guard
            elseKeyword.leadingTrivia.isEmpty,
            body.rightBrace.trailingTrivia.isSingleSpace == true
        else {
            violationPosition = body.rightBrace.positionAfterSkippingLeadingTrivia

            newNode.elseKeyword = elseKeyword.with(\.leadingTrivia, Trivia())
            newNode.body.rightBrace = body.rightBrace.with(\.trailingTrivia, .space)

            return (violationPosition, newNode)
        }

        return nil
    }

    func uncuddledModeViolationPosition() -> (position: AbsolutePosition, newNode: IfExprSyntax)? {
        func processViolation(elseKeyword: TokenSyntax, indentaion: Int) -> (AbsolutePosition, IfExprSyntax) {
            var newNode = self
            let violationPosition = body.rightBrace.positionAfterSkippingLeadingTrivia

            newNode.elseKeyword = elseKeyword.with(\.leadingTrivia, .newline + .spaces(indentaion))
            newNode.body.rightBrace = self.body.rightBrace.with(\.trailingTrivia, Trivia())

            return (violationPosition, newNode)
        }

        // Check if the node has `else` keyword
        guard let elseKeyword else {
            return nil
        }

        // Check if `else` has newline in leading trivia
        guard
            elseKeyword.leadingTrivia.containsNewlines() == true,
            body.rightBrace.trailingTrivia.isEmpty
        else {
            return processViolation(
                elseKeyword: elseKeyword,
                indentaion: self.elseBeforeIfKeyword?.indentation ?? ifKeyword.indentation
            )
        }

        // Now checking indentation.
        // If the node is `else if`, compare current `else` and child `else`'s indentation.
        // Otherwise, compare `if` itself and `else`'s indentation.
        if let elseBeforeIfKeyword = self.elseBeforeIfKeyword {
            if elseBeforeIfKeyword.indentation != elseKeyword.indentation {
                return processViolation(elseKeyword: elseKeyword, indentaion: elseBeforeIfKeyword.indentation)
            }
        } else {
            if ifKeyword.indentation != elseKeyword.indentation {
                return processViolation(elseKeyword: elseKeyword, indentaion: ifKeyword.indentation)
            }
        }

        return nil
    }
}

private extension DoStmtSyntax {
    func defaultModeViolationPositions() -> (positions: [AbsolutePosition], newNode: DoStmtSyntax)? {
        var newNode = self
        let originalCatchClauseArray = Array(catchClauses)
        var violationPositions: [AbsolutePosition] = []
        var newCatchClauses = Array(catchClauses)

        originalCatchClauseArray.enumerated().forEach { index, clause in
            guard
                clause.previousToken(viewMode: .sourceAccurate)?.isRightBrace == true,
                let previousRightBrace = clause.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let hasEmptyLeadingTrivia = clause.catchKeyword.leadingTrivia.isEmpty
            let trailingTriviaSingleSpace = previousRightBrace.trailingTrivia.isSingleSpace

            // If either of the above conditions are not met, record the violation position and update the clause
            if !hasEmptyLeadingTrivia || !trailingTriviaSingleSpace {
                violationPositions.append(
                    previousRightBrace.positionAfterSkippingLeadingTrivia
                )

                var newClause = clause
                // If it's the first catch clause, update the `do` body's right brace
                // Otherwise, Update the previous catch clause's right brace
                if index == 0 {
                    newNode.body.rightBrace = body.rightBrace.with(\.trailingTrivia, .space)
                } else {
                    let originalCatchClause = originalCatchClauseArray[index - 1]
                    newCatchClauses[index - 1] = originalCatchClause.with(\.body.rightBrace.trailingTrivia, .space)
                }
                newClause.catchKeyword = clause.catchKeyword.with(\.leadingTrivia, Trivia())
                newCatchClauses[index] = newClause
            }
        }
        newNode.catchClauses = CatchClauseListSyntax(newCatchClauses)

        return violationPositions.isEmpty ? nil : (violationPositions, newNode)
    }

    func uncuddledModeViolationPositions() -> (positions: [AbsolutePosition], newNode: DoStmtSyntax)? {
        var newNode = self
        let originalCatchClauseArray = Array(catchClauses)
        var violationPositions: [AbsolutePosition] = []
        var newCatchClauses = Array(catchClauses)

        originalCatchClauseArray.enumerated().forEach { index, clause in
            guard
                clause.previousToken(viewMode: .sourceAccurate)?.isRightBrace == true,
                let previousRightBrace = clause.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let hasNewline = clause.catchKeyword.leadingTrivia.containsNewlines()
            let trailingTriviaEmpty = previousRightBrace.trailingTrivia.isEmpty
            let indentationMismatch = clause.catchKeyword.indentation != doKeyword.indentation

            // If any of the conditions are not met, record the violation position and update the clause
            if !hasNewline || !trailingTriviaEmpty || indentationMismatch {
                violationPositions.append(
                    previousRightBrace.positionAfterSkippingLeadingTrivia
                )

                var newClause = clause
                // If it's the first catch clause, update the `do` body's right brace
                // Otherwise, update the current clause's body right brace
                if index == 0 {
                    newNode.body.rightBrace = body.rightBrace.with(\.trailingTrivia, Trivia())
                } else {
                    let originalCatchClause = originalCatchClauseArray[index - 1]
                    newCatchClauses[index - 1] = originalCatchClause.with(\.body.rightBrace.trailingTrivia, Trivia())
                }
                newClause.catchKeyword = clause.catchKeyword
                    .with(\.leadingTrivia, .newline + .spaces(doKeyword.indentation))
                newCatchClauses[index] = newClause
            }
        }
        newNode.catchClauses = CatchClauseListSyntax(newCatchClauses)

        return violationPositions.isEmpty ? nil : (violationPositions, newNode)
    }
}

private extension TokenSyntax {
    var isElseKeyword: Bool {
        tokenKind == .keyword(.else)
    }

    var isRightBrace: Bool {
        tokenKind == .rightBrace
    }

    var indentation: Int {
        return leadingTrivia.reduce(0) { count, piece -> Int in
            switch piece {
            case .spaces(let numSpaces):
                count + numSpaces
            case .tabs(let numTabs):
                count + numTabs * 4 // Assuming a tab is equal to 4 spaces
            default:
                count
            }
        }
    }
}
