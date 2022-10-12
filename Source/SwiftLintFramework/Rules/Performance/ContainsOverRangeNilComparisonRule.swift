import SwiftSyntax

public struct ContainsOverRangeNilComparisonRule: SourceKitFreeRule, OptInRule, ConfigurationProviderRule {
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree.folded() else {
            return []
        }

        return Visitor(viewMode: .sourceAccurate)
            .walk(tree: tree, handler: \.violationPositions)
            .map { position in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, position: position))
            }
    }
}

private extension ContainsOverRangeNilComparisonRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard
                let operatorNode = node.operatorOperand.as(BinaryOperatorExprSyntax.self),
                operatorNode.operatorToken.tokenKind.isEqualityComparison,
                node.rightOperand.is(NilLiteralExprSyntax.self),
                let first = node.leftOperand.as(FunctionCallExprSyntax.self),
                first.argumentList.count == 1,
                first.argumentList.first?.label?.text == "of",
                let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "range"
            else {
                return
            }

            violationPositions.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TokenKind {
    var isEqualityComparison: Bool {
        self == .spacedBinaryOperator("==") ||
            self == .spacedBinaryOperator("!=") ||
            self == .unspacedBinaryOperator("==")
    }
}
