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
        private func isMultilineFunction(_ node: FunctionDeclSyntax) -> Bool {
            guard let body = node.body else {
                return false
            }
            guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                return false
            }

            let startLocation = node.funcKeyword.endLocation(converter: locationConverter)
            let endLocation = endToken.endLocation(converter: locationConverter)
            let braceLocation = body.leftBrace.endLocation(converter: locationConverter)

            return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            let body = node.memberBlock
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: DeferStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            let body = node.body
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if let correction = node.violationCorrection(locationConverter) {
                violations.append(node.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if let body = node.body, let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if let body = node.accessorBlock, let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: PrecedenceGroupDeclSyntax) {
            if let correction = node.violationCorrection(locationConverter) {
                violations.append(node.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            let openingBrace = body.leftBrace

            if configuration.allowMultilineFunc && isMultilineFunction(node) {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else {
                if openingBrace.hasSingleSpaceLeading {
                    return
                }
            }

            let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
            violations.append(violationPosition)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }

            var isMultilineFunction: Bool {
                guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                    return false
                }

                let startLocation = node.initKeyword.endLocation(converter: locationConverter)
                let endLocation = endToken.endLocation(converter: locationConverter)
                let braceLocation = body.leftBrace.endLocation(converter: locationConverter)

                return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
            }

            let openingBrace = body.leftBrace

            if configuration.allowMultilineFunc && isMultilineFunction {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else if openingBrace.hasSingleSpaceLeading {
                return
            }

            let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
            violations.append(violationPosition)
        }
    }
}

private extension FunctionCallExprSyntax {
    var violationPosition: AbsolutePosition? {
        if let leftParen,
           let nextToken = leftParen.nextToken(viewMode: .sourceAccurate),
           case .leftBrace = nextToken.tokenKind {
            if !leftParen.trailingTrivia.isEmpty || !nextToken.leadingTrivia.isEmpty {
                return nextToken.positionAfterSkippingLeadingTrivia
            }
        }
        return nil
    }
}

private extension ClosureExprSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = leftBrace
        if let functionCall = parent?.as(FunctionCallExprSyntax.self) {
            if functionCall.calledExpression.as(ClosureExprSyntax.self) == self {
                return nil
            }
            if openingBrace.hasSingleSpaceLeading {
                return nil
            }
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        if let parent, parent.is(MultipleTrailingClosureElementSyntax.self) {
            if openingBrace.hasSingleSpaceLeading {
                return nil
            }
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        return nil
    }
}

private extension TokenSyntax {
    var hasSingleSpaceLeading: Bool {
        previousToken(viewMode: .sourceAccurate)?.trailingTrivia == .space
    }

    var hasOnlyWhitespaceInLeadingTrivia: Bool {
        leadingTrivia.pieces.allSatisfy { $0.isWhitespace }
    }
}

private extension BracedSyntax {
    var openingPosition: AbsolutePosition {
        leftBrace.positionAfterSkippingLeadingTrivia
    }

    func violationCorrection(_ locationConverter: SourceLocationConverter) -> ViolationCorrection? {
        if let previousToken = leftBrace.previousToken(viewMode: .sourceAccurate) {
            let previousLocation = previousToken.endLocation(converter: locationConverter)
            let leftBraceLocation = leftBrace.startLocation(converter: locationConverter)
            if previousLocation.line != leftBraceLocation.line
               || previousLocation.column + 1 != leftBraceLocation.column {
                return ViolationCorrection(
                    start: previousToken.endPositionBeforeTrailingTrivia,
                    end: leftBrace.positionAfterSkippingLeadingTrivia,
                    replacement: " "
                )
            }
        }
        return nil
    }
}

extension PrecedenceGroupDeclSyntax: BracedSyntax {}
