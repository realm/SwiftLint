import SwiftSyntax

struct StatementPositionRule: CorrectableRule {
    var configuration = StatementPositionConfiguration()

    static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the same line, one space after the previous declaration",
        kind: .style,
        nonTriggeringExamples: [
            Example("} else if {"),
            Example("} else {"),
            Example("} catch {"),
            Example("\"}else{\""),
            Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
            Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)")
        ],
        triggeringExamples: [
            Example("↓}else if {"),
            Example("↓}  else {"),
            Example("↓}\ncatch {"),
            Example("↓}\n\t  catch {")
        ],
        corrections: [
            Example("↓}\n else {"): Example("} else {"),
            Example("↓}\n   else if {"): Example("} else if {"),
            Example("↓}\n catch {"): Example("} catch {")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(statementMode: configuration.statementMode)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file),
            statementMode: configuration.statementMode
        )
    }
}

private extension StatementPositionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let statementMode: StatementMode

        init(statementMode: StatementMode) {
            self.statementMode = statementMode
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: IfExprSyntax) {
            switch statementMode {
            case .default:
                if let position = node.defaultModeViolationPosition()?.position {
                    violations.append(position)
                }
            case .uncuddledElse:
                if let position = node.uncuddledModeViolationPosition()?.position {
                    violations.append(position)
                }
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            switch statementMode {
            case .default:
                if let positions = node.defaultModeViolationPositions()?.positions {
                    violations.append(contentsOf: positions)
                }
            case .uncuddledElse:
                if let positions = node.uncuddledModeViolationPositions()?.positions {
                    violations.append(contentsOf: positions)
                }
            }
        }
    }
}

private extension StatementPositionRule {
    private class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        private let locationConverter: SourceLocationConverter
        private let disabledRegions: [SourceRange]

        private let statementMode: StatementMode

        init(locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange],
             statementMode: StatementMode) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
            self.statementMode = statementMode
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            let newNode: IfExprSyntax
            switch statementMode {
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
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            var newNode = node

            switch statementMode {
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
        if
            ifKeyword.previousToken(viewMode: .sourceAccurate)?.isElseKeyword == true,
            let elseBeforeIfKeyword = ifKeyword.previousToken(viewMode: .sourceAccurate)
        {
            return elseBeforeIfKeyword
        }

        return nil
    }

    func defaultModeViolationPosition() -> (position: AbsolutePosition, newNode: IfExprSyntax)? {
        let violationPosition: AbsolutePosition
        var newNode = self

        // Check if the node has `else` keyword
        guard let elseKeyword else {
            return nil
        }

        // Check if `else` doesn't have newline in leading trivia of `else`'and
        // multiple spaces in trailing trivia of `body`'s `rightBrace`
        guard
            elseKeyword.leadingTrivia.isEmpty,
            body.rightBrace.trailingTrivia.isSingleSpace == true
        else {
            violationPosition = body.rightBrace.endPositionBeforeTrailingTrivia

            newNode.elseKeyword = elseKeyword.with(\.leadingTrivia, Trivia())
            newNode.body.rightBrace = self.body.rightBrace.with(\.trailingTrivia, .space)

            return (violationPosition, newNode)
        }

        return nil
    }

    func uncuddledModeViolationPosition() -> (position: AbsolutePosition, newNode: IfExprSyntax)? {
        func processViolation(elseKeyword: TokenSyntax, indentaion: Int) -> (AbsolutePosition, IfExprSyntax) {
            var newNode = self
            let violationPosition = body.rightBrace.endPositionBeforeTrailingTrivia

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
        guard let catchClauses else {
            return nil
        }

        var newNode = self
        let originalCatchClauseArray = Array(catchClauses)
        var violationPositions: [AbsolutePosition] = []
        var newCatchClauses = catchClauses

        originalCatchClauseArray.enumerated().forEach { index, clause in
            guard
                clause.previousToken(viewMode: .sourceAccurate)?.isRightBrace == true,
                let previousRightBrace = clause.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let hasEmptyLeadingTrivia = clause.catchKeyword.leadingTrivia.isEmpty
            let trailingTriviaSingleSpace = (index == 0
                                             ? body.rightBrace
                                             : previousRightBrace).trailingTrivia.isSingleSpace

            // If either of the above conditions are not met, record the violation position and update the clause
            if !hasEmptyLeadingTrivia || !trailingTriviaSingleSpace {
                violationPositions.append(
                    (index == 0 ? body.rightBrace : previousRightBrace).endPositionBeforeTrailingTrivia
                )

                var newClause = clause
                // If it's the first catch clause, update the `do` body's right brace
                // Otherwise, Update the previous catch clause's right brace
                if index == 0 {
                    newNode.body.rightBrace = body.rightBrace.with(\.trailingTrivia, .space)
                } else {
                    newCatchClauses = newCatchClauses
                        .replacing(
                            childAt: index - 1,
                            with: originalCatchClauseArray[index - 1].with(\.body.rightBrace.trailingTrivia, .space)
                        )
                }
                newClause.catchKeyword = clause.catchKeyword.with(\.leadingTrivia, Trivia())
                newCatchClauses = newCatchClauses.replacing(childAt: index, with: newClause)
            }
        }
        newNode.catchClauses = newCatchClauses

        return violationPositions.isEmpty ? nil : (violationPositions, newNode)
    }

    func uncuddledModeViolationPositions() -> (positions: [AbsolutePosition], newNode: DoStmtSyntax)? {
        guard let catchClauses else {
            return nil
        }

        var newNode = self
        let originalCatchClauseArray = Array(catchClauses)
        var violationPositions: [AbsolutePosition] = []
        var newCatchClauses = catchClauses

        originalCatchClauseArray.enumerated().forEach { index, clause in
            guard
                clause.previousToken(viewMode: .sourceAccurate)?.isRightBrace == true,
                let previousRightBrace = clause.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let hasNewline = clause.catchKeyword.leadingTrivia.containsNewlines()
            let trailingTriviaEmpty = (index == 0 ? body.rightBrace : previousRightBrace).trailingTrivia.isEmpty
            let indentationMismatch = clause.catchKeyword.indentation != doKeyword.indentation

            // If any of the conditions are not met, record the violation position and update the clause
            if !hasNewline || !trailingTriviaEmpty || indentationMismatch {
                violationPositions.append(
                    (index == 0 ? body.rightBrace : previousRightBrace).endPositionBeforeTrailingTrivia
                )

                var newClause = clause
                // If it's the first catch clause, update the `do` body's right brace
                // Otherwise, update the current clause's body right brace
                if index == 0 {
                    newNode.body.rightBrace = body.rightBrace.with(\.trailingTrivia, Trivia())
                } else {
                    newCatchClauses = newCatchClauses
                        .replacing(
                            childAt: index - 1,
                            with: originalCatchClauseArray[index - 1].with(\.body.rightBrace.trailingTrivia, Trivia())
                        )
                }
                newClause.catchKeyword = clause.catchKeyword
                    .with(\.leadingTrivia, .newline + .spaces(doKeyword.indentation))
                newCatchClauses = newCatchClauses.replacing(childAt: index, with: newClause)
            }
        }
        newNode.catchClauses = newCatchClauses

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
                return count + numSpaces
            case .tabs(let numTabs):
                return count + numTabs * 4 // Assuming a tab is equal to 4 spaces
            default:
                return count
            }
        }
    }
}
