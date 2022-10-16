import SwiftSyntax

public struct ContainsOverRangeNilComparisonRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_range_nil_comparison",
        name: "Contains over range(of:) comparison to nil",
        description: "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let range = myString.range(of: \"Test\")"),
            Example("myString.contains(\"Test\")"),
            Example("!myString.contains(\"Test\")"),
            Example("resourceString.range(of: rule.regex, options: .regularExpression) != nil")
        ],
        triggeringExamples: ["!=", "=="].flatMap { comparison in
            return [
                Example("↓myString.range(of: \"Test\") \(comparison) nil")
            ]
        }
    )

    public func preprocess(syntaxTree: SourceFileSyntax) -> SourceFileSyntax? {
        syntaxTree.folded()
    }

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ContainsOverRangeNilComparisonRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard
                let operatorNode = node.operatorOperand.as(BinaryOperatorExprSyntax.self),
                operatorNode.operatorToken.tokenKind.isEqualityComparison,
                node.rightOperand.is(NilLiteralExprSyntax.self),
                let first = node.leftOperand.asFunctionCall,
                first.argumentList.count == 1,
                first.argumentList.first?.label?.text == "of",
                let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "range"
            else {
                return
            }

            violationPositions.append(first.positionAfterSkippingLeadingTrivia)
        }
    }
}
