import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct OpeningBraceRule: SwiftSyntaxCorrectableRule {
    var configuration = OpeningBraceConfiguration()

    static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: """
            The correct positioning of braces that introduce a block of code or member list is highly controversial. \
            No matter which style is preferred, consistency is key. Apart from different tastes, \
            the positioning of braces can also have a significant impact on the readability of the code, \
            especially for visually impaired developers. This rule ensures that braces are preceded \
            by a single space and on the same line as the declaration. Comments between the declaration and the \
            opening brace are respected. Check out the `contrasted_opening_brace` rule for a different style.
            """,
        kind: .style,
        nonTriggeringExamples: OpeningBraceRuleExamples.nonTriggeringExamples,
        triggeringExamples: OpeningBraceRuleExamples.triggeringExamples,
        corrections: OpeningBraceRuleExamples.corrections
    )
}

private extension OpeningBraceRule {
    final class Visitor: CodeBlockVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.funcKeyword) {
                return
            }
            collectViolations(for: body)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.initKeyword) {
                return
            }
            collectViolations(for: body)
        }

        private func refersToMultilineFunction(_ body: CodeBlockSyntax, functionIndicator: TokenSyntax) -> Bool {
            guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                return false
            }
            let startLocation = functionIndicator.endLocation(converter: locationConverter)
            let endLocation = endToken.endLocation(converter: locationConverter)
            let braceLocation = body.leftBrace.endLocation(converter: locationConverter)
            return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
        }

        override func collectViolations(for bracedItem: (some BracedSyntax)?) {
            if let bracedItem, let correction = violationCorrection(bracedItem) {
                violations.append(
                    ReasonedRuleViolation(
                        position: bracedItem.openingPosition,
                        reason: """
                              Opening braces should be preceded by a single space and on the same line \
                              as the declaration
                              """,
                        correction: correction
                    )
                )
            }
        }

        private func violationCorrection(_ node: some BracedSyntax) -> ReasonedRuleViolation.ViolationCorrection? {
            let leftBrace = node.leftBrace
            guard let previousToken = leftBrace.previousToken(viewMode: .sourceAccurate) else {
                return nil
            }
            let openingPosition = node.openingPosition
            let triviaBetween = previousToken.trailingTrivia + leftBrace.leadingTrivia
            let previousLocation = previousToken.endLocation(converter: locationConverter)
            let leftBraceLocation = leftBrace.startLocation(converter: locationConverter)
            if previousLocation.line != leftBraceLocation.line {
                return .init(
                    start: previousToken.endPositionBeforeTrailingTrivia,
                    end: openingPosition,
                    replacement: " "
                )
            }
            if previousLocation.column + 1 == leftBraceLocation.column {
                return nil
            }
            if triviaBetween.containsComments {
                if triviaBetween.pieces.last == .spaces(1) {
                    return nil
                }
                let comment = triviaBetween.description.trimmingTrailingCharacters(in: .whitespaces)
                return .init(
                    start: previousToken.endPositionBeforeTrailingTrivia + SourceLength(of: comment),
                    end: openingPosition,
                    replacement: " "
                )
            }
            return .init(
                start: previousToken.endPositionBeforeTrailingTrivia,
                end: openingPosition,
                replacement: " "
            )
        }
    }
}

private extension BracedSyntax {
    var openingPosition: AbsolutePosition {
        leftBrace.positionAfterSkippingLeadingTrivia
    }
}
