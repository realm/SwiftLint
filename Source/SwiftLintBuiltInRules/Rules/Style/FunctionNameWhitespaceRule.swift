import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct FunctionNameWhitespaceRule: Rule {
    var configuration = FunctionNameWhitespaceConfiguration()

    static let description = RuleDescription(
        identifier: "function_name_whitespace",
        name: "Function Name Whitespace",
        description: "Function declaration should have exactly one space before the name and no space after it",
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

            correctSingleCommentTriviaIfNeeded(name: node.name)
            handleGenericTrailingTriviaComment(node: node)

            let genericTrailingTrivia = node.genericParameterClause?.rightAngle.trailingTrivia

            switch configuration.genericSpace {
            case .noSpace:
                if node.name.trailingTrivia.isNotEmptyWithoutComments {
                    violationAndCorrection(
                        name: node.name,
                        replacement: ""
                    )
                }

                correctSingleCommentTrivia(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia?.isNotEmptyWithoutComments ?? false,
                    replacement: ""
                )
            case .leadingSpace:
                if node.name.trailingTrivia.isNotSingleSpaceWithoutComments {
                    violationAndCorrection(
                        name: node.name,
                        replacement: " "
                    )
                }

                correctSingleCommentTrivia(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia?.isNotEmptyWithoutComments ?? false,
                    replacement: ""
                )
            case .trailingSpace:
                if node.name.trailingTrivia.isNotEmptyWithoutComments {
                    violationAndCorrection(
                        name: node.name,
                        replacement: ""
                    )
                }
                correctSingleCommentTrivia(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia?.isNotSingleSpaceWithoutComments ?? false,
                    replacement: " "
                )
            case .leadingTrailingSpace:
                if node.name.trailingTrivia.isNotSingleSpaceWithoutComments {
                    violationAndCorrection(
                        name: node.name,
                        replacement: " "
                    )
                }
                correctSingleCommentTrivia(
                    genericParameterClause: node.genericParameterClause,
                    isNeeded: genericTrailingTrivia?.isNotSingleSpaceWithoutComments ?? false,
                    replacement: " "
                )
            }
        }

        private func validateFuncKeywordSpacing(for node: FunctionDeclSyntax) {
            guard node.funcKeyword.trailingTrivia.isNotSingleSpaceWithoutComments else { return }
            violations.append(
                at: node.name.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: node.funcKeyword.endPositionBeforeTrailingTrivia,
                    end: node.name.positionAfterSkippingLeadingTrivia,
                    replacement: " "
                )
            )
        }

        private func handleGenericTrailingTriviaComment(
            node: FunctionDeclSyntax
        ) {
            guard let genericParameterClause = node.genericParameterClause else { return }
            guard genericParameterClause.rightAngle.trailingTrivia.isNotEmptyWithComments else { return }
            guard let comment = genericParameterClause.trailingTrivia.singleComment else { return }
            let expectedTrivia = Trivia.surroundedBySpaces(comment: comment)
            guard genericParameterClause.rightAngle.trailingTrivia != expectedTrivia else { return }
            violationAndCorrection(
                genericParameterClause: genericParameterClause,
                replacement: " \(comment) "
            )
        }

        private func violationAndCorrection(
            genericParameterClause: GenericParameterClauseSyntax,
            replacement: String
        ) {
            let correctionStart = genericParameterClause.endPositionBeforeTrailingTrivia
            let correctionEnd = correctionStart.advanced(
                by: genericParameterClause.trailingTriviaLength.utf8Length
            )

            violations.append(
                at: genericParameterClause.positionAfterSkippingLeadingTrivia,
                correction: ReasonedRuleViolation.ViolationCorrection(
                    start: correctionStart,
                    end: correctionEnd,
                    replacement: replacement
                )
            )
        }

        private func violationAndCorrection(
            name: TokenSyntax,
            replacement: String
        ) {
            let correctionStart = name.endPositionBeforeTrailingTrivia
            let correctionEnd = correctionStart.advanced(
                by: name.trailingTriviaLength.utf8Length
            )

            violations.append(
                at: name.positionAfterSkippingLeadingTrivia,
                correction: ReasonedRuleViolation.ViolationCorrection(
                    start: correctionStart,
                    end: correctionEnd,
                    replacement: replacement
                )
            )
        }

        private func correctSingleCommentTriviaIfNeeded(name: TokenSyntax) {
            guard name.trailingTrivia.isNotEmptyWithComments else { return }
            guard let comment = name.trailingTrivia.singleComment else { return }
            let expectedTrivia = Trivia.surroundedBySpaces(comment: comment)
            guard name.trailingTrivia != expectedTrivia else { return }

            violationAndCorrection(
                name: name,
                replacement: " \(comment) "
            )
        }

        private func correctSingleCommentTrivia(
            genericParameterClause: GenericParameterClauseSyntax?,
            isNeeded: Bool,
            replacement: String
        ) {
            guard let genericParameterClause else { return }
            guard isNeeded else { return }
            violationAndCorrection(
                genericParameterClause: genericParameterClause,
                replacement: replacement
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
        let comments = self.filter(\.isComment)
        return comments.count == 1 ? comments.first : nil
    }

    static func surroundedBySpaces(comment: TriviaPiece) -> Trivia {
        Trivia(pieces: [.spaces(1), comment, .spaces(1)])
    }

    var isNotEmptyWithoutComments: Bool {
        isNotEmpty && !containsComments
    }

    var isNotEmptyWithComments: Bool {
        isNotEmpty && containsComments
    }

    var isNotSingleSpaceWithoutComments: Bool {
        !isSingleSpace && !containsComments
    }
}
