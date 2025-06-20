import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct VerticalWhitespaceClosingBracesRule: Rule {
    var configuration = VerticalWhitespaceClosingBracesConfiguration()

    static let description = RuleDescription(
        identifier: "vertical_whitespace_closing_braces",
        name: "Vertical Whitespace before Closing Braces",
        description: "Don't include vertical whitespace (empty line) before closing braces",
        kind: .style,
        nonTriggeringExamples: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.values.sorted() +
                               VerticalWhitespaceClosingBracesRuleExamples.nonTriggeringExamples,
        triggeringExamples: Array(VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.keys.sorted()),
        corrections: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.removingViolationMarkers()
    )
}

private struct TriviaAnalysis {
    var consecutiveNewlines = 0
    var violationStartPosition: AbsolutePosition?
    var violationEndPosition: AbsolutePosition?
}

private struct CorrectionState {
    var result = [TriviaPiece]()
    var consecutiveNewlines = 0
    var pendingWhitespace = [TriviaPiece]()
    var correctionCount = 0
    var hasViolation = false
}

private struct NewlineProcessingContext {
    let currentPosition: AbsolutePosition
    let consecutiveNewlines: Int
    var violationStartPosition: AbsolutePosition?
    var violationEndPosition: AbsolutePosition?
}

private func isTokenLineTrivialHelper(
    for token: TokenSyntax,
    file: SwiftLintFile,
    locationConverter: SourceLocationConverter
) -> Bool {
    let lineColumn = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia)
    let line = lineColumn.line

    guard let lineContent = file.lines.first(where: { $0.index == line })?.content else {
        return false
    }

    let trimmedLine = lineContent.trimmingCharacters(in: .whitespaces)
    let closingBraces: Set<Character> = ["]", "}", ")"]
    return !trimmedLine.isEmpty && trimmedLine.allSatisfy { closingBraces.contains($0) }
}

private extension VerticalWhitespaceClosingBracesRule {
    final class Visitor: ViolationsSyntaxVisitor<VerticalWhitespaceClosingBracesConfiguration> {
        override func visitPost(_ node: TokenSyntax) {
            guard node.isClosingBrace else {
                return
            }

            let triviaAnalysis = analyzeTriviaForViolations(
                trivia: node.leadingTrivia,
                token: node,
                position: node.position
            )

            if let violation = triviaAnalysis {
                violations.append(
                    ReasonedRuleViolation(
                        position: violation.position,
                        correction: .init(
                            start: violation.position,
                            end: violation.endPosition,
                            replacement: ""
                        )
                    )
                )
            }
        }

        private func analyzeTriviaForViolations(
            trivia: Trivia,
            token: TokenSyntax,
            position: AbsolutePosition
        ) -> (position: AbsolutePosition, endPosition: AbsolutePosition)? {
            let analysis = analyzeTrivia(trivia: trivia, startPosition: position)

            guard let startPos = analysis.violationStartPosition,
                  let endPos = analysis.violationEndPosition,
                  analysis.consecutiveNewlines >= 2 else {
                return nil
            }

            if configuration.onlyEnforceBeforeTrivialLines &&
                !isTokenLineTrivialHelper(for: token, file: file, locationConverter: locationConverter) {
                return nil
            }

            return (position: startPos, endPosition: endPos)
        }

        private func analyzeTrivia(
            trivia: Trivia,
            startPosition: AbsolutePosition
        ) -> TriviaAnalysis {
            var result = TriviaAnalysis()
            var currentPosition = startPosition

            for piece in trivia {
                let (newlines, positionAdvance) = processTriviaPiece(
                    piece: piece,
                    currentPosition: currentPosition,
                    consecutiveNewlines: result.consecutiveNewlines,
                    violationStartPosition: &result.violationStartPosition,
                    violationEndPosition: &result.violationEndPosition
                )
                result.consecutiveNewlines = newlines
                currentPosition = currentPosition.advanced(by: positionAdvance)
            }

            return result
        }

        private func processTriviaPiece(
            piece: TriviaPiece,
            currentPosition: AbsolutePosition,
            consecutiveNewlines: Int,
            violationStartPosition: inout AbsolutePosition?,
            violationEndPosition: inout AbsolutePosition?
        ) -> (newlines: Int, positionAdvance: Int) {
            switch piece {
            case .newlines(let count), .carriageReturns(let count):
                var context = NewlineProcessingContext(
                    currentPosition: currentPosition,
                    consecutiveNewlines: consecutiveNewlines,
                    violationStartPosition: violationStartPosition,
                    violationEndPosition: violationEndPosition
                )
                let result = processNewlines(
                    count: count,
                    bytesPerNewline: 1,
                    context: &context
                )
                violationStartPosition = context.violationStartPosition
                violationEndPosition = context.violationEndPosition
                return result
            case .carriageReturnLineFeeds(let count):
                var context = NewlineProcessingContext(
                    currentPosition: currentPosition,
                    consecutiveNewlines: consecutiveNewlines,
                    violationStartPosition: violationStartPosition,
                    violationEndPosition: violationEndPosition
                )
                let result = processNewlines(
                    count: count,
                    bytesPerNewline: 2,
                    context: &context
                )
                violationStartPosition = context.violationStartPosition
                violationEndPosition = context.violationEndPosition
                return result
            case .spaces, .tabs:
                return (consecutiveNewlines, piece.sourceLength.utf8Length)
            default:
                // Any other trivia breaks the sequence
                violationStartPosition = nil
                violationEndPosition = nil
                return (0, piece.sourceLength.utf8Length)
            }
        }

        private func processNewlines(
            count: Int,
            bytesPerNewline: Int,
            context: inout NewlineProcessingContext
        ) -> (newlines: Int, positionAdvance: Int) {
            var newConsecutiveNewlines = context.consecutiveNewlines
            var totalAdvance = 0

            for _ in 0..<count {
                newConsecutiveNewlines += 1
                // violationStartPosition marks the beginning of the first newline
                // that constitutes an empty line (i.e., the second in a sequence of \n\n).
                if newConsecutiveNewlines == 2 && context.violationStartPosition == nil {
                    context.violationStartPosition = context.currentPosition.advanced(by: totalAdvance)
                }
                // violationEndPosition tracks the end of the last newline in any sequence of >= 2 newlines.
                if newConsecutiveNewlines >= 2 {
                    context.violationEndPosition = context.currentPosition.advanced(by: totalAdvance + bytesPerNewline)
                }
                totalAdvance += bytesPerNewline
            }

            return (newConsecutiveNewlines, totalAdvance)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<VerticalWhitespaceClosingBracesConfiguration> {
        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            guard token.isClosingBrace else {
                return super.visit(token)
            }

            let correctedTrivia = correctTrivia(
                trivia: token.leadingTrivia,
                token: token
            )

            if correctedTrivia.hasCorrections {
                numberOfCorrections += correctedTrivia.correctionCount
                return super.visit(token.with(\.leadingTrivia, correctedTrivia.trivia))
            }

            return super.visit(token)
        }

        private func correctTrivia(
            trivia: Trivia,
            token: TokenSyntax
        ) -> (trivia: Trivia, hasCorrections: Bool, correctionCount: Int) {
            // First check if we should apply corrections
            if configuration.onlyEnforceBeforeTrivialLines &&
                !isTokenLineTrivialHelper(for: token, file: file, locationConverter: locationConverter) {
                return (trivia: trivia, hasCorrections: false, correctionCount: 0)
            }

            var state = CorrectionState()

            for piece in trivia {
                processPieceForCorrection(piece: piece, state: &state)
            }

            // Add any remaining whitespace
            state.result.append(contentsOf: state.pendingWhitespace)

            return (trivia: Trivia(pieces: state.result),
                    hasCorrections: state.correctionCount > 0,
                    correctionCount: state.correctionCount)
        }

        private func processPieceForCorrection(piece: TriviaPiece, state: inout CorrectionState) {
            switch piece {
            case .newlines(let count), .carriageReturns(let count):
                let newlineCreator = piece.isNewline ? TriviaPiece.newlines : TriviaPiece.carriageReturns
                processNewlinesForCorrection(
                    count: count,
                    newlineCreator: { newlineCreator($0) },
                    state: &state
                )
            case .carriageReturnLineFeeds(let count):
                processNewlinesForCorrection(
                    count: count,
                    newlineCreator: { TriviaPiece.carriageReturnLineFeeds($0) },
                    state: &state
                )
            case .spaces, .tabs:
                // Only keep whitespace if we haven't seen a violation yet
                if !state.hasViolation {
                    state.pendingWhitespace.append(piece)
                }
            default:
                // Other trivia breaks the sequence
                state.consecutiveNewlines = 0
                state.hasViolation = false
                state.result.append(contentsOf: state.pendingWhitespace)
                state.result.append(piece)
                state.pendingWhitespace.removeAll()
            }
        }

        private func processNewlinesForCorrection(
            count: Int,
            newlineCreator: (Int) -> TriviaPiece,
            state: inout CorrectionState
        ) {
            for _ in 0..<count {
                state.consecutiveNewlines += 1
                if state.consecutiveNewlines == 1 {
                    // First newline - always keep it with any preceding whitespace
                    state.result.append(contentsOf: state.pendingWhitespace)
                    state.result.append(newlineCreator(1))
                    state.pendingWhitespace.removeAll()
                } else {
                    // Additional newlines - these form empty lines and should be removed
                    state.hasViolation = true
                    state.correctionCount += 1
                    state.pendingWhitespace.removeAll()
                }
            }
        }
    }
}

private extension TokenSyntax {
    var isClosingBrace: Bool {
        switch tokenKind {
        case .rightBrace, .rightParen, .rightSquare:
            return true
        default:
            return false
        }
    }
}

private extension TriviaPiece {
    var isNewline: Bool {
        switch self {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
            return true
        default:
            return false
        }
    }
}
