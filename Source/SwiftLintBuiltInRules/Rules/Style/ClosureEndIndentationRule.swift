import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct ClosureEndIndentationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: ClosureEndIndentationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureEndIndentationRuleExamples.triggeringExamples,
        corrections: ClosureEndIndentationRuleExamples.corrections
    )
}

private extension ClosureEndIndentationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            // Get locations of opening and closing braces
            let leftBraceLocation = locationConverter.location(
                for: node.leftBrace.positionAfterSkippingLeadingTrivia
            )
            let rightBracePositionAfterTrivia = node.rightBrace.positionAfterSkippingLeadingTrivia
            let rightBraceLocation = locationConverter.location(for: rightBracePositionAfterTrivia)

            // Only interested in multi-line closures
            let leftBraceLine = leftBraceLocation.line
            let rightBraceLine = rightBraceLocation.line
            guard rightBraceLine > leftBraceLine else {
                return
            }

            // Find the position that the closing brace should align with
            guard let anchorPosition = findAnchorPosition(for: node) else {
                return
            }

            let anchorLocation = locationConverter.location(for: anchorPosition)
            let anchorLineNumber = anchorLocation.line

            // Calculate expected indentation
            let expectedIndentationColumn = getFirstNonWhitespaceColumn(onLine: anchorLineNumber) - 1

            // Calculate actual indentation of the closing brace
            let actualIndentationColumn = rightBraceLocation.column - 1

            if actualIndentationColumn != expectedIndentationColumn {
                // Check if there's leading trivia on the right brace that ends with a newline and only whitespace
                // after it.
                let leadingTriviaEndsWithNewline = node.rightBrace.leadingTrivia
                    .reversed()
                    .drop(while: \.isSpaceOrTab)
                    .first
                    .map(\.isNewline) ?? false

                let (correctionStartPosition, correctionPartBeforeIndentation) =
                    if leadingTriviaEndsWithNewline {
                        // If there's already a newline, we just need to fix the indentation.
                        // The range to replace is the trivia before the brace.
                        (
                            locationConverter.position(ofLine: rightBraceLocation.line, column: 1),
                            ""
                        )
                    } else {
                        // If no newline, we need to add one. The replacement will be inserted
                        // after the previous token and before the closing brace.
                        (
                            node.rightBrace.positionAfterSkippingLeadingTrivia,
                            "\n"
                        )
                    }

                let reason = "expected \(expectedIndentationColumn), got \(actualIndentationColumn)"
                violations.append(
                    ReasonedRuleViolation(
                        position: node.rightBrace.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: configuration.severity,
                        correction: .init(
                            start: correctionStartPosition,
                            end: node.rightBrace.positionAfterSkippingLeadingTrivia,
                            replacement: correctionPartBeforeIndentation
                                + String(repeating: " ", count: max(0, expectedIndentationColumn))
                        )
                    )
                )
            }
        }

        /// Finds the position of a token that the closure's closing brace should be aligned with.
        private func findAnchorPosition(for closureNode: ClosureExprSyntax) -> AbsolutePosition? {
            guard let parent = closureNode.parent else {
                return nil
            }

            // Case: Trailing closure. e.g., `list.map { ... }`
            if let functionCall = parent.as(FunctionCallExprSyntax.self),
               closureNode.id == functionCall.trailingClosure?.id {
                return anchor(for: ExprSyntax(functionCall))
            }

            // Case: Closure as a labeled argument. e.g., `function(label: { ... })`
            if let labeledExpr = parent.as(LabeledExprSyntax.self) {
                // Check if this is part of a function call where the first argument is on a new line
                if let argList = labeledExpr.parent?.as(LabeledExprListSyntax.self),
                   let functionCall = argList.parent?.as(FunctionCallExprSyntax.self),
                   let firstArg = argList.first,
                   let leftParen = functionCall.leftParen {
                    // Get the location of the opening paren and first argument
                    let leftParenLocation = locationConverter.location(
                        for: leftParen.positionAfterSkippingLeadingTrivia
                    )
                    let firstArgLocation = locationConverter.location(
                        for: firstArg.positionAfterSkippingLeadingTrivia
                    )

                    // If first argument is on the same line as the opening paren, don't apply the rule
                    if leftParenLocation.line == firstArgLocation.line {
                        return nil
                    }
                }

                // The anchor is the start of the argument expression (including the label).
                if let label = labeledExpr.label {
                    return label.positionAfterSkippingLeadingTrivia
                }
                return labeledExpr.positionAfterSkippingLeadingTrivia
            }

            // Case: Multiple trailing closures. e.g., `function { ... } another: { ... }`
            if let multipleTrailingClosure = parent.as(MultipleTrailingClosureElementSyntax.self) {
                // The anchor is the label of the specific trailing closure.
                return multipleTrailingClosure.label.positionAfterSkippingLeadingTrivia
            }

            // For closures on new lines after function calls
            if let exprList = parent.as(ExprListSyntax.self),
               exprList.count == 1,
               exprList.parent?.as(FunctionCallExprSyntax.self) != nil {
                // This is a closure on its own line after a function call like:
                // foo(abc, 123)
                // { _ in }
                return closureNode.positionAfterSkippingLeadingTrivia
            }

            // Fallback for other cases (e.g., closure in an array literal).
            // The anchor is the start of the parent syntax node.
            return closureNode.positionAfterSkippingLeadingTrivia
        }

        /// Recursively traverses a chain of expressions (e.g., member access or function calls)
        /// to find the token that begins the statement. This is the token that the closure's
        /// closing brace should ultimately be aligned with.
        /// - Parameter expression: The expression to find the anchor for.
        /// - Returns: The absolute position of the anchor token.
        private func anchor(for expression: ExprSyntax) -> AbsolutePosition {
            if let memberAccess = expression.as(MemberAccessExprSyntax.self), let base = memberAccess.base {
                let baseAnchor = anchor(for: base)

                let memberStartPosition = memberAccess.period.positionAfterSkippingLeadingTrivia
                let baseEndPosition = base.endPositionBeforeTrailingTrivia

                let memberStartLocation = locationConverter.location(for: memberStartPosition)
                let baseEndLocation = locationConverter.location(for: baseEndPosition)

                if memberStartLocation.line > baseEndLocation.line {
                    return memberStartPosition
                }

                return baseAnchor
            }
            if let functionCallExpr = expression.as(FunctionCallExprSyntax.self) {
                return anchor(for: functionCallExpr.calledExpression)
            }
            if let subscriptExpr = expression.as(SubscriptCallExprSyntax.self) {
                return anchor(for: subscriptExpr.calledExpression)
            }
            if let optionalChainingExpr = expression.as(OptionalChainingExprSyntax.self) {
                return anchor(for: optionalChainingExpr.expression)
            }
            if let forceUnwrapExpr = expression.as(ForceUnwrapExprSyntax.self) {
                return anchor(for: forceUnwrapExpr.expression)
            }
            return expression.positionAfterSkippingLeadingTrivia
        }

        /// Calculates the column of the first non-whitespace character on a given line.
        private func getFirstNonWhitespaceColumn(onLine lineNumber: Int) -> Int {
            guard lineNumber > 0, lineNumber <= file.lines.count else {
                return 1 // Should not happen
            }
            let lineContent = file.lines[lineNumber - 1].content

            if let firstCharIndex = lineContent.firstIndex(where: { !$0.isWhitespace }) {
                return lineContent.distance(from: lineContent.startIndex, to: firstCharIndex) + 1
            }
            return 1 // Empty or whitespace-only line
        }
    }
}
