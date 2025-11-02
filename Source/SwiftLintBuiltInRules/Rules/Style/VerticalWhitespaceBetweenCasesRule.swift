import SwiftBasicFormat
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct VerticalWhitespaceBetweenCasesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "vertical_whitespace_between_cases",
        name: "Vertical Whitespace Between Cases",
        description: "Include a single empty line between switch cases",
        kind: .style,
        nonTriggeringExamples: VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples.values.sorted() +
                               VerticalWhitespaceBetweenCasesRuleExamples.nonTriggeringExamples,
        triggeringExamples: Array(VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples.keys.sorted()),
        corrections: VerticalWhitespaceBetweenCasesRuleExamples.violatingToValidExamples.removingViolationMarkers()
    )
}

private extension VerticalWhitespaceBetweenCasesRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private lazy var emptyLines = EmptyLinesVisitor.emptyLines(in: file)

        override func visitPost(_ cases: SwitchCaseListSyntax) {
            for index in cases.indices.dropLast() {
                let nextIndex = cases.index(after: index)
                let element = cases[index]
                let nextElement = cases[nextIndex]
                if let currentCase = element.as(SwitchCaseSyntax.self),
                   let nextCase = nextElement.as(SwitchCaseSyntax.self),
                   shouldSkipCasePair(currentCase, nextCase) {
                    continue
                }
                let endLineOfCurrentCase = locationConverter.location(for: element.endPosition).line
                let startLineOfNextCase = locationConverter.location(
                    for: nextElement.positionAfterSkippingLeadingTrivia
                ).line
                guard !emptyLines.contains(endLineOfCurrentCase + 1), !emptyLines.contains(startLineOfNextCase - 1),
                      let commentIndentation = nextElement.leadingTrivia.indentation(isOnNewline: true),
                      let caseIndentation = nextElement.indentation.indentation(isOnNewline: true) else {
                    continue
                }
                let correctionPosition =
                    if commentIndentation == caseIndentation {
                        // Comment is probably attached to the next case.
                        element.endPosition
                    } else {
                        // Comment is probably part of the previous case block.
                        nextElement.positionAfterSkippingLeadingTrivia.advanced(
                            by: -caseIndentation.sourceLength.utf8Length
                        )
                    }
                violations.append(.init(
                    position: nextElement.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: correctionPosition,
                        end: correctionPosition,
                        replacement: "\n"
                    )
                ))
            }
        }

        private func shouldSkipCasePair(_ currentCase: SwitchCaseSyntax, _ nextCase: SwitchCaseSyntax) -> Bool {
            let currentCaseStartLine = locationConverter.location(
                for: currentCase.positionAfterSkippingLeadingTrivia
            ).line
            let currentCaseEndLine = locationConverter.location(
                for: currentCase.statements.last?.endPosition ?? currentCase.endPosition
            ).line
            let nextCaseStartLine = locationConverter.location(
                for: nextCase.positionAfterSkippingLeadingTrivia
            ).line
            let nextCaseEndLine = locationConverter.location(
                for: nextCase.statements.last?.endPosition ?? nextCase.endPosition
            ).line

            let currentIsOneLiner = currentCaseStartLine == currentCaseEndLine
            let nextIsOneLiner = nextCaseStartLine == nextCaseEndLine

            // Skip if both are one-liners on consecutive lines.
            return currentIsOneLiner && nextIsOneLiner && nextCaseStartLine == currentCaseStartLine + 1
        }
    }
}

private extension SyntaxProtocol {
    var indentation: Trivia {
        Trivia(pieces: leadingTrivia.reversed().prefix(while: \.isSpaceOrTab).reversed())
    }
}
