import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct ContainsOverRangeNilComparisonRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contains_over_range_nil_comparison",
        name: "Contains over Range Comparison to Nil",
        description: "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let range = myString.range(of: \"Test\")"),
            Example("myString.contains(\"Test\")"),
            Example("!myString.contains(\"Test\")"),
            Example("resourceString.range(of: rule.regex, options: .regularExpression) != nil"),
        ],
        triggeringExamples: ["!=", "=="].flatMap { comparison in
            [
                Example("↓myString.range(of: \"Test\") \(comparison) nil")
            ]
        }
    )
}

private extension ContainsOverRangeNilComparisonRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard
                let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
                operatorNode.operator.tokenKind.isEqualityComparison,
                node.rightOperand.is(NilLiteralExprSyntax.self),
                let first = node.leftOperand.asFunctionCall,
                first.arguments.onlyElement?.label?.text == "of",
                let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.declName.baseName.text == "range"
            else {
                return
            }

            violations.append(first.positionAfterSkippingLeadingTrivia)
        }
    }
}
