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

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let parent = node.parent else {
                return
            }
            if parent.is(LabeledExprSyntax.self) {
                // Function parameter
                return
            }
            if parent.is(FunctionCallExprSyntax.self) || parent.is(MultipleTrailingClosureElementSyntax.self),
               node.keyPathInParent != \FunctionCallExprSyntax.calledExpression,
               let correction = node.violationCorrection(locationConverter) {
                // Trailing closure
                violations.append(node.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }
            let openingBrace = body.leftBrace
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.funcKeyword) {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else if openingBrace.hasSingleSpaceLeading {
                return
            }
            violations.append(body.openingPosition)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }
            let openingBrace = body.leftBrace
            if configuration.allowMultilineFunc, refersToMultilineFunction(body, functionIndicator: node.initKeyword) {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else if openingBrace.hasSingleSpaceLeading {
                return
            }
            violations.append(body.openingPosition)
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
