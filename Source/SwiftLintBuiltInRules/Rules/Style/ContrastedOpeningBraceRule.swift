import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct ContrastedOpeningBraceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contrasted_opening_brace",
        name: "Contrasted Opening Brace",
        description: """
            The correct positioning of braces that introduce a block of code or member list is highly controversial. \
            No matter which style is preferred, consistency is key. Apart from different tastes, \
            the positioning of braces can also have a significant impact on the readability of the code, \
            especially for visually impaired developers. This rule ensures that braces are on a separate line \
            after the declaration to contrast the code block from the rest of the declaration. Comments between the \
            declaration and the opening brace are respected. Check out the `opening_brace` rule for a different style.
            """,
        kind: .style,
        nonTriggeringExamples: ContrastedOpeningBraceRuleExamples.nonTriggeringExamples,
        triggeringExamples: ContrastedOpeningBraceRuleExamples.triggeringExamples,
        corrections: ContrastedOpeningBraceRuleExamples.corrections
    )
}

private extension ContrastedOpeningBraceRule {
    final class Visitor: CodeBlockVisitor<ConfigurationType> {
        override func collectViolations(for bracedItem: (some BracedSyntax)?) {
            if let bracedItem, let correction = violationCorrection(bracedItem) {
                violations.append(
                    ReasonedRuleViolation(
                        position: bracedItem.openingPosition,
                        reason: "Opening brace should be on a separate line",
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
            let parentStartColumn = node
                .indentationDecidingParent?
                .startLocation(converter: locationConverter)
                .column ?? 1
            if previousLocation.line + 1 == leftBraceLocation.line, leftBraceLocation.column == parentStartColumn {
                return nil
            }
            let comment = triviaBetween.description.trimmingTrailingCharacters(in: .whitespacesAndNewlines)
            return .init(
                start: previousToken.endPositionBeforeTrailingTrivia + SourceLength(of: comment),
                end: openingPosition,
                replacement: "\n" + String(repeating: " ", count: parentStartColumn - 1)
            )
        }
    }
}

private extension BracedSyntax {
    var openingPosition: AbsolutePosition {
        leftBrace.positionAfterSkippingLeadingTrivia
    }

    var indentationDecidingParent: (any SyntaxProtocol)? {
        if let catchClause = parent?.as(CatchClauseSyntax.self) {
            return catchClause.parent?.as(CatchClauseListSyntax.self)?.parent?.as(DoStmtSyntax.self)
        }
        if let ifExpr = parent?.as(IfExprSyntax.self) {
            return ifExpr.indentationDecidingParent
        }
        if let binding = parent?.as(PatternBindingSyntax.self) {
            return binding.parent?.as(PatternBindingListSyntax.self)?.parent?.as(VariableDeclSyntax.self)
        }
        if let closure = `as`(ClosureExprSyntax.self),
           closure.keyPathInParent == \FunctionCallExprSyntax.trailingClosure {
           return closure.leftBrace.previousIndentationDecidingToken
        }
        if let closureLabel = parent?.as(MultipleTrailingClosureElementSyntax.self)?.label {
            return closureLabel.previousIndentationDecidingToken
        }
        return parent
    }
}

private extension TokenSyntax {
    var previousIndentationDecidingToken: TokenSyntax {
        var indentationDecidingToken = self
        repeat {
            if let previousToken = indentationDecidingToken.previousToken(viewMode: .sourceAccurate) {
                indentationDecidingToken = previousToken
            } else {
                break
            }
        } while !indentationDecidingToken.leadingTrivia.containsNewlines()
        return indentationDecidingToken
    }
}

private extension IfExprSyntax {
    var indentationDecidingParent: any SyntaxProtocol {
        if keyPathInParent == \IfExprSyntax.elseBody, let parent = parent?.as(IfExprSyntax.self) {
            return parent.indentationDecidingParent
        }
        return self
    }
}
