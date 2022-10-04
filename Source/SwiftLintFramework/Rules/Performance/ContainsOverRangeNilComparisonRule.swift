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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ContainsOverRangeNilComparisonRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: ExprListSyntax) {
            guard
                node.count == 3,
                node.last?.is(NilLiteralExprSyntax.self) == true,
                let second = node.dropFirst().first,
                second.firstToken?.tokenKind.isEqualityComparison == true,
                let first = node.first?.as(FunctionCallExprSyntax.self),
                first.argumentList.count == 1,
                first.argumentList.allSatisfy({ $0.label?.text == "of" }),
                let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "range"
            else {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
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
