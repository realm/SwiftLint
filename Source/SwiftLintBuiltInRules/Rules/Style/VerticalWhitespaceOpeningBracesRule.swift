// swiftlint:disable file_length
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct VerticalWhitespaceOpeningBracesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    private static let nonTriggeringExamples = [
        Example("[1, 2].map { $0 }.foo()"),
        Example("[1, 2].map { $0 }.filter { num in true }"),
        Example("// [1, 2].map { $0 }.filter { num in true }"),
        Example("""
        /*
            class X {

                let x = 5

            }
        */
        """),
    ]

    private static let violatingToValidExamples: [Example: Example] = [
        Example("""
        if x == 5 {
        ↓
          print("x is 5")
        }
        """): Example("""
            if x == 5 {
              print("x is 5")
            }
            """),
        Example("""
        if x == 5 {
        ↓

          print("x is 5")
        }
        """): Example("""
            if x == 5 {
              print("x is 5")
            }
            """),
        Example("""
        struct MyStruct {
        ↓
          let x = 5
        }
        """): Example("""
            struct MyStruct {
              let x = 5
            }
            """),
        Example("""
        class X {
          struct Y {
        ↓
            class Z {
            }
          }
        }
        """): Example("""
            class X {
              struct Y {
                class Z {
                }
              }
            }
            """),
        Example("""
        [
        ↓
        1,
        2,
        3
        ]
        """): Example("""
            [
            1,
            2,
            3
            ]
            """),
        Example("""
        foo(
        ↓
          x: 5,
          y:6
        )
        """): Example("""
            foo(
              x: 5,
              y:6
            )
            """),
        Example("""
        func foo() {
        ↓
          run(5) { x in
            print(x)
          }
        }
        """): Example("""
            func foo() {
              run(5) { x in
                print(x)
              }
            }
            """),
        Example("""
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
        ↓
            guard let img = image else { return }
        }
        """): Example("""
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
                guard let img = image else { return }
            }
            """),
        Example("""
        foo({ }) { _ in
        ↓
          self.dismiss(animated: false, completion: {
          })
        }
        """): Example("""
            foo({ }) { _ in
              self.dismiss(animated: false, completion: {
              })
            }
            """),
    ]

    static let description = RuleDescription(
        identifier: "vertical_whitespace_opening_braces",
        name: "Vertical Whitespace after Opening Braces",
        description: "Don't include vertical whitespace (empty line) after opening braces",
        kind: .style,
        nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
        triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
        corrections: violatingToValidExamples.removingViolationMarkers()
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
    var correctionCount = 0
    var hasViolation = false
}

private struct NewlineProcessingContext {
    let currentPosition: AbsolutePosition
    let consecutiveNewlines: Int
    var violationStartPosition: AbsolutePosition?
    var violationEndPosition: AbsolutePosition?
}

private extension VerticalWhitespaceOpeningBracesRule {
    final class Visitor: ViolationsSyntaxVisitor<SeverityConfiguration<VerticalWhitespaceOpeningBracesRule>> {
        override func visitPost(_ node: TokenSyntax) {
            // Check for violations after opening braces
            if node.isOpeningBrace {
                checkForViolationAfterToken(node)
            }
            // Check for violations after "in" keywords in closures
            else if node.tokenKind == .keyword(.in) {
                // Check if this "in" is part of a closure signature
                if isClosureSignatureIn(node) {
                    checkForViolationAfterToken(node)
                }
            }
        }

        private func isClosureSignatureIn(_ inToken: TokenSyntax) -> Bool {
            // Check if the "in" token is part of a closure signature by looking at its parent
            var currentNode = Syntax(inToken)
            while let parent = currentNode.parent {
                if parent.is(ClosureSignatureSyntax.self) {
                    return true
                }
                // Stop traversing if we hit a different expression or declaration
                if parent.is(ExprSyntax.self) || parent.is(DeclSyntax.self) {
                    break
                }
                currentNode = parent
            }
            return false
        }

        private func checkForViolationAfterToken(_ token: TokenSyntax) {
            // We analyze the trivia of the token immediately following the token
            if let nextToken = token.nextToken(viewMode: .sourceAccurate) {
                let triviaAnalysis = analyzeTriviaForViolations(
                    trivia: nextToken.leadingTrivia,
                    position: token.endPositionBeforeTrailingTrivia
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
        }

        private func analyzeTriviaForViolations(
            trivia: Trivia,
            position: AbsolutePosition
        ) -> (position: AbsolutePosition, endPosition: AbsolutePosition)? {
            let analysis = analyzeTrivia(trivia: trivia, startPosition: position)

            guard let startPos = analysis.violationStartPosition,
                  let endPos = analysis.violationEndPosition,
                  analysis.consecutiveNewlines >= 2 else {
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

    final class Rewriter: ViolationsSyntaxRewriter<SeverityConfiguration<VerticalWhitespaceOpeningBracesRule>> {
        override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
            // Handle code blocks with opening braces
            if let firstStatement = node.statements.first {
                let leadingTrivia = firstStatement.leadingTrivia
                let correctedTrivia = correctTrivia(trivia: leadingTrivia)
                if correctedTrivia.hasCorrections {
                    numberOfCorrections += correctedTrivia.correctionCount
                    var newStatements = node.statements
                    newStatements[newStatements.startIndex] = firstStatement
                        .with(\.leadingTrivia, correctedTrivia.trivia)
                    return node.with(\.statements, newStatements)
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            // Handle closures with "in" keyword  
            if let firstStatement = node.statements.first {
                let leadingTrivia = firstStatement.leadingTrivia
                let correctedTrivia = correctTrivia(trivia: leadingTrivia)
                if correctedTrivia.hasCorrections {
                    numberOfCorrections += correctedTrivia.correctionCount
                    var newStatements = node.statements
                    newStatements[newStatements.startIndex] = firstStatement
                        .with(\.leadingTrivia, correctedTrivia.trivia)
                    return ExprSyntax(node.with(\.statements, newStatements))
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
            // Handle array literals
            if let firstElement = node.elements.first {
                let leadingTrivia = firstElement.leadingTrivia
                let correctedTrivia = correctTrivia(trivia: leadingTrivia)
                if correctedTrivia.hasCorrections {
                    numberOfCorrections += correctedTrivia.correctionCount
                    var newElements = node.elements
                    newElements[newElements.startIndex] = firstElement.with(\.leadingTrivia, correctedTrivia.trivia)
                    return ExprSyntax(node.with(\.elements, newElements))
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: TupleExprSyntax) -> ExprSyntax {
            // Handle tuples and function arguments
            if let firstElement = node.elements.first {
                let leadingTrivia = firstElement.leadingTrivia
                let correctedTrivia = correctTrivia(trivia: leadingTrivia)
                if correctedTrivia.hasCorrections {
                    numberOfCorrections += correctedTrivia.correctionCount
                    var newElements = node.elements
                    newElements[newElements.startIndex] = firstElement.with(\.leadingTrivia, correctedTrivia.trivia)
                    return ExprSyntax(node.with(\.elements, newElements))
                }
            }
            return super.visit(node)
        }

        private func correctTrivia(
            trivia: Trivia
        ) -> (trivia: Trivia, hasCorrections: Bool, correctionCount: Int) {
            var state = CorrectionState()

            for piece in trivia {
                processPieceForCorrection(piece: piece, state: &state)
            }

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
                state.result.append(piece)
            default:
                // Other trivia breaks the sequence
                state.consecutiveNewlines = 0
                state.hasViolation = false
                state.result.append(piece)
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
                    // First newline - always keep it
                    state.result.append(newlineCreator(1))
                } else {
                    // Additional newlines - these form empty lines and should be removed
                    state.hasViolation = true
                    state.correctionCount += 1
                }
            }
        }
    }
}

private extension TokenSyntax {
    var isOpeningBrace: Bool {
        switch tokenKind {
        case .leftBrace, .leftParen, .leftSquare:
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
