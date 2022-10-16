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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension LegacyConstantRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: IdentifierExprSyntax) {
            if LegacyConstantRuleExamples.patterns.keys.contains(node.identifier.text) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.isLegacyPiExpression {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
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
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
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
                node.isLegacyPiExpression,
                let calledExpression = node.calledExpression.as(IdentifierExprSyntax.self),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return ("\(calledExpression.identifier.text).pi" as ExprSyntax)
                .withLeadingTrivia(node.leadingTrivia ?? .zero)
                .withTrailingTrivia(node.trailingTrivia ?? .zero)
        }
    }
}

private extension FunctionCallExprSyntax {
    var isLegacyPiExpression: Bool {
        guard
            let calledExpression = calledExpression.as(IdentifierExprSyntax.self),
            calledExpression.identifier.text == "CGFloat" || calledExpression.identifier.text == "Float",
            argumentList.count == 1,
            let argument = argumentList.first?.expression.as(IdentifierExprSyntax.self),
            argument.identifier.text == "M_PI"
        else {
            return false
        }

        return true
    }
}
