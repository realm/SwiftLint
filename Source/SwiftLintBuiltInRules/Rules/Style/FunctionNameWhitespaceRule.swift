import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct FunctionNameWhitespaceRule: Rule {
    var configuration = FunctionNameWhitespaceConfiguration()

    static let description = RuleDescription(
        identifier: "function_name_whitespace",
        name: "Function Name Whitespace",
        description: "Checks whitespace before and after function name and generics",
        kind: .style,
        nonTriggeringExamples: FunctionNameWhitespaceRuleExamples.nonTriggeringExamples,
        triggeringExamples: FunctionNameWhitespaceRuleExamples.triggeringExamples,
        corrections: FunctionNameWhitespaceRuleExamples.corrections
    )
}

private extension FunctionNameWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isNamedFunction else { return }

            validateFuncKeywordSpacing(for: node)

            correctSingleCommentTriviaIfNeeded(
                trivia: node.name.trailingTrivia,
                correctionStart: node.name.endPositionBeforeTrailingTrivia,
                position: node.name.positionAfterSkippingLeadingTrivia,
                reason: configuration.genericSpace.reasonForName
            )
            if let genericParameterClause = node.genericParameterClause {
                correctSingleCommentTriviaIfNeeded(
                    trivia: genericParameterClause.rightAngle.trailingTrivia,
                    correctionStart: genericParameterClause.endPositionBeforeTrailingTrivia,
                    position: genericParameterClause.positionAfterSkippingLeadingTrivia,
                    reason: configuration.genericSpace.reasonForGenericAngleBracket
                )
            }

            validateGenericSpacing(node: node)
            switch configuration.genericSpace {
            case .noSpace:
                violationAndCorrection(
                    name: node.name,
                    isNeeded: node.name.trailingTrivia.isNotEmptyWithoutComments,
                    replacement: ""
                )
            case .leadingSpace:
                violationAndCorrection(
                    name: node.name,
                    isNeeded: node.name.trailingTrivia.isNotSingleSpaceWithoutComments,
                    replacement: " "
                )
            case .trailingSpace:
                violationAndCorrection(
                    name: node.name,
                    isNeeded: node.name.trailingTrivia.isNotEmptyWithoutComments,
                    replacement: ""
                )
            case .leadingTrailingSpace:
                violationAndCorrection(
                    name: node.name,
                    isNeeded: node.name.trailingTrivia.isNotSingleSpaceWithoutComments,
                    replacement: " "
                )
            }
        }

        private func validateFuncKeywordSpacing(for node: FunctionDeclSyntax) {
            guard node.funcKeyword.trailingTrivia.isNotSingleSpaceWithoutComments else { return }

            violations.append(
                ReasonedRuleViolation(
                    position: node.name.positionAfterSkippingLeadingTrivia,
                    reason: "There should be no space before the function name",
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: node.funcKeyword.endPositionBeforeTrailingTrivia,
                        end: node.name.positionAfterSkippingLeadingTrivia,
                        replacement: " "
                    )
                )
            )
        }

        private func validateGenericSpacing(node: FunctionDeclSyntax) {
            guard let genericTrailingTrivia = node.genericParameterClause?.rightAngle.trailingTrivia else { return }
            switch configuration.genericSpace {
            case .noSpace:
                violationAndCorrection(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia.isNotEmptyWithoutComments,
                    replacement: ""
                )
            case .leadingSpace:
                violationAndCorrection(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia.isNotEmptyWithoutComments,
                    replacement: ""
                )
            case .trailingSpace:
                violationAndCorrection(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia.isNotSingleSpaceWithoutComments,
                    replacement: " "
                )
            case .leadingTrailingSpace:
                violationAndCorrection(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia.isNotSingleSpaceWithoutComments,
                    replacement: " "
                )
            }
        }

        private func violationAndCorrection(
            genericParameterClause: GenericParameterClauseSyntax?,
            isNeeded: Bool,
            replacement: String
        ) {
            guard let clause = genericParameterClause, isNeeded else { return }

            let correctionStart = clause.endPositionBeforeTrailingTrivia
            let correctionEnd = correctionStart.advanced(
                by: clause.trailingTriviaLength.utf8Length
            )

            violations.append(
                ReasonedRuleViolation(
                    position: clause.positionAfterSkippingLeadingTrivia,
                    reason: configuration.genericSpace.reasonForGenericAngleBracket,
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: correctionStart,
                        end: correctionEnd,
                        replacement: replacement
                    )
                )
            )
        }

        private func violationAndCorrection(
            name: TokenSyntax,
            isNeeded: Bool,
            replacement: String
        ) {
            guard isNeeded else { return }

            let correctionStart = name.endPositionBeforeTrailingTrivia
            let correctionEnd = correctionStart.advanced(
                by: name.trailingTriviaLength.utf8Length
            )

            violations.append(
                ReasonedRuleViolation(
                    position: name.positionAfterSkippingLeadingTrivia,
                    reason: configuration.genericSpace.reasonForName,
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: correctionStart,
                        end: correctionEnd,
                        replacement: replacement
                    )
                )
            )
        }

        private func correctSingleCommentTriviaIfNeeded(
            trivia: Trivia,
            correctionStart: AbsolutePosition,
            position: AbsolutePosition,
            reason: String
        ) {
            guard trivia.containsComments else { return }
            guard let comment = trivia.singleComment else { return }
            let expectedTrivia = Trivia.surroundedBySpaces(comment: comment)
            guard trivia != expectedTrivia else { return }

            let correctionEnd = correctionStart.advanced(
                by: trivia.description.utf8.count
            )

            violations.append(
                ReasonedRuleViolation(
                    position: position,
                    reason: reason,
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: correctionStart,
                        end: correctionEnd,
                        replacement: " \(comment) "
                    )
                )
            )
        }
    }
}

private extension FunctionDeclSyntax {
    var isNamedFunction: Bool {
        guard case .identifier = name.tokenKind else { return false }
        return true
    }
}

private extension Trivia {
    var singleComment: TriviaPiece? {
        filter(\.isComment).onlyElement
    }

    static func surroundedBySpaces(comment: TriviaPiece) -> Trivia {
        Trivia(pieces: [.spaces(1), comment, .spaces(1)])
    }

    var isNotEmptyWithoutComments: Bool {
        isNotEmpty && !containsComments
    }

    var isNotSingleSpaceWithoutComments: Bool {
        !isSingleSpace && !containsComments
    }
}
