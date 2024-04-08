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
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.actorKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            let body = node.memberBlock
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.classKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            let body = node.memberBlock
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.enumKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            let body = node.memberBlock
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.extensionKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            let body = node.memberBlock
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.protocolKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            let body = node.memberBlock
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.structKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.catchKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: DeferStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.deferKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.doKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.forKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.guardKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            let body = node.body
            if !isIgnoredMultilineConditionStatement(body, keywordToken: node.ifKeyword),
               let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
            if case let .codeBlock(body) = node.elseBody, let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.repeatKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            let body = node.body
            if isIgnoredMultilineConditionStatement(body, keywordToken: node.whileKeyword) {
                return
            }
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
            if isIgnoredMultilineFunc(body, keywordToken: node.funcKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }
            if isIgnoredMultilineFunc(body, keywordToken: node.initKeyword) {
                return
            }
            if let correction = body.violationCorrection(locationConverter) {
                violations.append(body.openingPosition)
                violationCorrections.append(correction)
            }
        }

        private func isIgnoredMultilineFunc(_ body: CodeBlockSyntax, keywordToken: TokenSyntax) -> Bool {
            guard configuration.allowMultilineFunc else {
                return false
            }

            return isBodyPredecessorMultiline(body, keywordToken: keywordToken)
        }

        private func isIgnoredMultilineConditionStatement(_ body: some BracedSyntax, keywordToken: TokenSyntax) -> Bool {
            guard configuration.ignoreMultilineConditionStatement else {
                return false
            }

            return isBodyPredecessorMultiline(body, keywordToken: keywordToken)
        }

        private func isBodyPredecessorMultiline(_ body: some BracedSyntax, keywordToken: TokenSyntax) -> Bool {
            guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                return false
            }

            let bodyPredecessorsStartLocation = keywordToken.endLocation(converter: locationConverter)
            let bodyPredecessorsEndLocation = endToken.endLocation(converter: locationConverter)
            let braceLocation = body.leftBrace.endLocation(converter: locationConverter)

            return bodyPredecessorsStartLocation.line != bodyPredecessorsEndLocation.line
                && bodyPredecessorsEndLocation.line != braceLocation.line
        }
    }
}

private extension BracedSyntax {
    var openingPosition: AbsolutePosition {
        leftBrace.positionAfterSkippingLeadingTrivia
    }

    func violationCorrection(_ locationConverter: SourceLocationConverter) -> ViolationCorrection? {
        guard let previousToken = leftBrace.previousToken(viewMode: .sourceAccurate) else {
            return nil
        }

        let previousLocation = previousToken.endLocation(converter: locationConverter)
        let leftBraceLocation = leftBrace.startLocation(converter: locationConverter)

        let leftBraceIsInSameLine = previousLocation.line == leftBraceLocation.line
        let leftBraceHasOneLeadingSpace = previousLocation.column + 1 == leftBraceLocation.column

        if !leftBraceIsInSameLine || !leftBraceHasOneLeadingSpace {
            return ViolationCorrection(
                start: previousToken.endPositionBeforeTrailingTrivia,
                end: leftBrace.positionAfterSkippingLeadingTrivia,
                replacement: " "
            )
        }

        return nil
    }
}
