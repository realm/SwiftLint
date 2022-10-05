import SwiftSyntax
import SwiftSyntaxBuilder

public struct LegacyConstantRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_constant",
        name: "Legacy Constant",
        description: "Struct-scoped constants are preferred over legacy global constants.",
        kind: .idiomatic,
        nonTriggeringExamples: LegacyConstantRuleExamples.nonTriggeringExamples,
        triggeringExamples: LegacyConstantRuleExamples.triggeringExamples,
        corrections: LegacyConstantRuleExamples.corrections
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension LegacyConstantRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: IdentifierExprSyntax) {
            if LegacyConstantRuleExamples.patterns.keys.contains(node.identifier.text) {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(IdentifierExprSyntax.self),
                calledExpression.identifier.text == "CGFloat" || calledExpression.identifier.text == "Float",
                node.argumentList.count == 1,
                let argument = node.argumentList.first?.expression.as(IdentifierExprSyntax.self),
                argument.identifier.text == "M_PI"
            else {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: IdentifierExprSyntax) -> ExprSyntax {
            guard
                let correction = LegacyConstantRuleExamples.patterns[node.identifier.text],
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return ("\(correction)" as ExprSyntax)
                .withLeadingTrivia(node.leadingTrivia ?? .zero)
                .withTrailingTrivia(node.trailingTrivia ?? .zero)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                let calledExpression = node.calledExpression.as(IdentifierExprSyntax.self),
                calledExpression.identifier.text == "CGFloat" || calledExpression.identifier.text == "Float",
                node.argumentList.count == 1,
                let argument = node.argumentList.first?.expression.as(IdentifierExprSyntax.self),
                argument.identifier.text == "M_PI",
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return ("\(calledExpression.identifier.text).pi" as ExprSyntax)
                .withLeadingTrivia(node.leadingTrivia ?? .zero)
                .withTrailingTrivia(node.trailingTrivia ?? .zero)
        }

        private func isInDisabledRegion<T: SyntaxProtocol>(_ node: T) -> Bool {
            disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }
        }
    }
}

private extension FunctionTypeSyntax {
    var emptyParametersViolationPosition: AbsolutePosition? {
        guard
            arguments.count == 1,
            leftParen.presence == .present,
            rightParen.presence == .present,
            let argument = arguments.first,
            let simpleType = argument.type.as(SimpleTypeIdentifierSyntax.self),
            simpleType.typeName == "Void"
        else {
            return nil
        }

        return leftParen.positionAfterSkippingLeadingTrivia
    }
}
