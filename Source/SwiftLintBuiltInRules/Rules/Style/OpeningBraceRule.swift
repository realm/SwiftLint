import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

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

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            configuration: configuration,
            disabledRegions: disabledRegions(file: file),
            locationConverter: file.locationConverter
        )
    }
}
// swiftlint:enable type_body_length

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
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: DeferStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            guard let openingBrace = node.accessorBlock?.leftBrace else {
                return
            }
            if !openingBrace.hasSingleSpaceLeading {
                let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: PrecedenceGroupDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
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
            } else {
                if openingBrace.hasSingleSpaceLeading {
                    return
                }
            }

            let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
            violations.append(violationPosition)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let configuration: OpeningBraceConfiguration

        init(
            configuration: OpeningBraceConfiguration,
            disabledRegions: [SourceRange],
            locationConverter: SourceLocationConverter
        ) {
            self.configuration = configuration
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.extendedType))
            }

            return super.visit(node)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.primaryAssociatedTypeClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                if node.catchItems.isEmpty {
                    return super.visit(node.correct(keyPath: \.catchKeyword))
                }
                return super.visit(node.correct(keyPath: \.catchItems))
            }

            return super.visit(node)
        }

        override func visit(_ node: DeferStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.deferKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.doKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.whereClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.sequence))
            }

            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.elseKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.conditions))
            }

            return super.visit(node)
        }

        override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.repeatKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.conditions))
            }

            return super.visit(node)
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node
                        .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                        .with(\.leftBrace.leadingTrivia, [])
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node.with(\.accessorSpecifier, node.accessorSpecifier.with(\.trailingTrivia, .space))
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node
                        .with(\.name, node.name.with(\.trailingTrivia, .space))
                        .with(\.leftBrace, node.leftBrace.with(\.leadingTrivia, []))
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.with(\.leftParen, node.leftParen?.with(\.trailingTrivia, [])))
            }

            return super.visit(node)
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.with(\.leftBrace, node.leftBrace.with(\.leadingTrivia, .space)))
            }

            return super.visit(node)
        }
    }
}

private extension DeclGroupSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = memberBlock.leftBrace
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        return nil
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T>) -> Self {
        return self
            .with(keyPath, self[keyPath: keyPath].with(\.trailingTrivia, .space))
            .with(\.memberBlock, memberBlock.with(\.leadingTrivia, []))
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T?>) -> Self? {
        guard let value = self[keyPath: keyPath] else {
            return nil
        }
        return self
            .with(keyPath, value.with(\.trailingTrivia, .space))
            .with(\.memberBlock, memberBlock.with(\.leadingTrivia, []))
    }
}

private extension WithCodeBlockSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = body.leftBrace
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        return nil
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T>) -> Self {
        return self
            .with(keyPath, self[keyPath: keyPath].with(\.trailingTrivia, .space))
            .with(\.body, body.with(\.leadingTrivia, []))
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T?>) -> Self? {
        guard let value = self[keyPath: keyPath] else {
            return nil
        }
        return self
            .with(keyPath, value.with(\.trailingTrivia, .space))
            .with(\.body, body.with(\.leadingTrivia, []))
    }
}

private extension BracedSyntax {
    var violationPosition: AbsolutePosition? {
        if !leftBrace.hasSingleSpaceLeading {
            return leftBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension AccessorDeclSyntax {
    var violationPosition: AbsolutePosition? {
        guard let openingBrace = body?.leftBrace else {
            return nil
        }
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension PrecedenceGroupDeclSyntax {
    var violationPosition: AbsolutePosition? {
        if !leftBrace.hasSingleSpaceLeading {
            return leftBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
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
        if let previousToken = previousToken(viewMode: .sourceAccurate),
           previousToken.trailingTrivia == .space {
            return true
        } else {
            return false
        }
    }

    var hasOnlyWhitespaceInLeadingTrivia: Bool {
        leadingTrivia.pieces.allSatisfy { $0.isWhitespace }
    }
}
