import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct FunctionNameWhitespaceRule: Rule {
    var configuration = FunctionNameWhitespaceConfiguration()

    static let description = RuleDescription(
        identifier: "function_name_whitespace",
        name: "Function Name Whitespace",
        description: "There should be consistent whitespace before and after function names and generic parameters.",
        kind: .style,
        nonTriggeringExamples: FunctionNameWhitespaceRuleExamples.nonTriggeringExamples,
        triggeringExamples: FunctionNameWhitespaceRuleExamples.triggeringExamples,
        corrections: FunctionNameWhitespaceRuleExamples.corrections,
        deprecatedAliases: ["operator_whitespace"]
    )
}

private extension FunctionNameWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            validateFuncKeywordSpacing(for: node)
            correctSingleCommentTrivia(
                after: node.name,
                reason: configuration.genericSpacing.beforeGenericViolationReason
            )
            validateFunctionNameTrailingTrivia(node: node)
            if let genericParameterClause = node.genericParameterClause {
                correctSingleCommentTrivia(
                    after: genericParameterClause,
                    reason: configuration.genericSpacing.afterGenericViolationReason
                )
                validateGenericTrailingTrivia(node: genericParameterClause)
            }
        }

        private func validateFunctionNameTrailingTrivia(node: FunctionDeclSyntax) {
            let nameTrailingTrivia = node.name.trailingTrivia
            let replacement: String? =
                if node.isOperatorDeclaration {
                    nameTrailingTrivia.isNotSingleSpaceWithoutComments ? " " : nil
                } else {
                    switch configuration.genericSpacing {
                    case .noSpace where nameTrailingTrivia.isNotEmptyWithoutComments: ""
                    case .leadingSpace where nameTrailingTrivia.isNotSingleSpaceWithoutComments: " "
                    case .trailingSpace where nameTrailingTrivia.isNotEmptyWithoutComments: ""
                    case .leadingTrailingSpace where nameTrailingTrivia.isNotSingleSpaceWithoutComments: " "
                    default: nil
                    }
                }

            guard let replacement else { return }
            violations.append(
                .init(
                    position: node.name.endPositionBeforeTrailingTrivia,
                    reason: node.isOperatorDeclaration
                        ? "Operators should be surrounded by a single whitespace when defining them"
                        : configuration.genericSpacing.beforeGenericViolationReason,
                    correction: .init(
                        start: node.name.endPositionBeforeTrailingTrivia,
                        end: node.name.endPosition,
                        replacement: replacement
                    )
                )
            )
        }

        private func validateFuncKeywordSpacing(for node: FunctionDeclSyntax) {
            guard node.funcKeyword.trailingTrivia.isNotSingleSpaceWithoutComments else { return }
            violations.append(
                .init(
                    position: node.funcKeyword.endPositionBeforeTrailingTrivia,
                    reason: node.isOperatorDeclaration
                        ? "Operators should be surrounded by a single whitespace when defining them"
                        : "Too many spaces between 'func' and function name",
                    correction: .init(
                        start: node.funcKeyword.endPositionBeforeTrailingTrivia,
                        end: node.name.positionAfterSkippingLeadingTrivia,
                        replacement: " "
                    )
                )
            )
        }

        private func validateGenericTrailingTrivia(node: GenericParameterClauseSyntax) {
            let genericTrailingTrivia = node.rightAngle.trailingTrivia
            let replacement: String? = switch configuration.genericSpacing {
                case .noSpace where genericTrailingTrivia.isNotEmptyWithoutComments: ""
                case .leadingSpace where genericTrailingTrivia.isNotEmptyWithoutComments: ""
                case .trailingSpace where genericTrailingTrivia.isNotSingleSpaceWithoutComments: " "
                case .leadingTrailingSpace where genericTrailingTrivia.isNotSingleSpaceWithoutComments: " "
                default: nil
                }
            guard let replacement else { return }
            violations.append(
                .init(
                    position: node.endPositionBeforeTrailingTrivia,
                    reason: configuration.genericSpacing.afterGenericViolationReason,
                    correction: .init(
                        start: node.endPositionBeforeTrailingTrivia,
                        end: node.endPosition,
                        replacement: replacement
                    )
                )
            )
        }

        private func correctSingleCommentTrivia(after node: some SyntaxProtocol, reason: String) {
            let trivia = node.trailingTrivia
            guard trivia.containsComments else { return }
            guard let comment = trivia.singleComment else { return }
            let expectedTrivia = Trivia.surroundedBySpaces(comment: comment)
            guard trivia != expectedTrivia else { return }

            violations.append(
                .init(
                    position: node.endPositionBeforeTrailingTrivia,
                    reason: reason,
                    correction: .init(
                        start: node.endPositionBeforeTrailingTrivia,
                        end: node.endPosition,
                        replacement: " \(comment) "
                    )
                )
            )
        }
    }
}

private extension FunctionDeclSyntax {
    var isOperatorDeclaration: Bool {
        switch name.tokenKind {
        case .binaryOperator: true
        default: false
        }
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
