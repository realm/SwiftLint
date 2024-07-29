import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct OpeningBraceRule: SwiftSyntaxCorrectableRule {
    var configuration = OpeningBraceConfiguration()

    static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration",
        kind: .style,
        nonTriggeringExamples: OpeningBraceRuleExamples.nonTriggeringExamples,
        triggeringExamples: OpeningBraceRuleExamples.triggeringExamples,
        corrections: OpeningBraceRuleExamples.corrections
    )
}

private extension OpeningBraceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ActorDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolation(for: node.memberBlock)
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: DeferStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: DoStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: ForStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: IfExprSyntax) {
            collectViolation(for: node.body)
            if case let .codeBlock(body) = node.elseBody {
                collectViolation(for: body)
            }
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            collectViolation(for: node)
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            collectViolation(for: node.body)
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            collectViolation(for: node.accessorBlock)
        }

        override func visitPost(_ node: PrecedenceGroupDeclSyntax) {
            collectViolation(for: node)
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let parent = node.parent else {
                return
            }
            if parent.is(LabeledExprSyntax.self) {
                // Function parameter
                return
            }
            if parent.is(FunctionCallExprSyntax.self) || parent.is(MultipleTrailingClosureElementSyntax.self),
               node.keyPathInParent != \FunctionCallExprSyntax.calledExpression {
                // Trailing closure
                collectViolation(for: node)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.funcKeyword) {
                return
            }
            collectViolation(for: body)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.initKeyword) {
                return
            }
            collectViolation(for: body)
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

        private func collectViolation(for bracedItem: (some BracedSyntax)?) {
            if let bracedItem, let correction = violationCorrection(bracedItem) {
                violations.append(
                    ReasonedRuleViolation(
                        position: bracedItem.openingPosition,
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
