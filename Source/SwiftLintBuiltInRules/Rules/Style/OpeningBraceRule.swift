import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct OpeningBraceRule: Rule {
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
        // MARK: - Type Declarations

        override func visitPost(_ node: ActorDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.actorKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.classKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.enumKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.extensionKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.protocolKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if configuration.ignoreMultilineTypeHeaders,
                hasMultilinePredecessors(node.memberBlock, keyword: node.structKeyword) {
                return
            }

            super.visitPost(node)
        }

        // MARK: - Conditional Statements

        override func visitPost(_ node: ForStmtSyntax) {
            if configuration.ignoreMultilineStatementConditions,
                hasMultilinePredecessors(node.body, keyword: node.forKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: IfExprSyntax) {
            if configuration.ignoreMultilineStatementConditions,
                hasMultilinePredecessors(node.body, keyword: node.ifKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if configuration.ignoreMultilineStatementConditions,
                hasMultilinePredecessors(node.body, keyword: node.whileKeyword) {
                return
            }

            super.visitPost(node)
        }

        // MARK: - Functions and Initializers

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let body = node.body,
                configuration.shouldIgnoreMultilineFunctionSignatures,
                hasMultilinePredecessors(body, keyword: node.funcKeyword) {
                return
            }

            super.visitPost(node)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if let body = node.body,
                configuration.shouldIgnoreMultilineFunctionSignatures,
                hasMultilinePredecessors(body, keyword: node.initKeyword) {
                return
            }

            super.visitPost(node)
        }

        // MARK: - Other Methods

        /// Checks if a `BracedSyntax` has a multiline predecessor.
        /// For type declarations, the predecessor is the header. For conditional statements,
        /// it is the condition list, and for functions, it is the signature.
        private func hasMultilinePredecessors(_ body: some BracedSyntax, keyword: TokenSyntax) -> Bool {
            guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                return false
            }
            let startLocation = keyword.endLocation(converter: locationConverter)
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
                let trailingCommentText = previousToken.trailingTrivia.description.trimmingCharacters(in: .whitespaces)
                return .init(
                    start: previousToken.endPositionBeforeTrailingTrivia,
                    end: openingPosition.advanced(by: trailingCommentText.isNotEmpty ? 1 : 0),
                    replacement: trailingCommentText.isNotEmpty ? " { \(trailingCommentText)" : " "
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
