import SwiftSyntax

public struct FlatMapOverMapReduceRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "flatmap_over_map_reduce",
        name: "FlatMap over map and reduce",
        description: "Prefer `flatMap` over `map` followed by `reduce([], +)`.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let foo = bar.map { $0.count }.reduce(0, +)"),
            Example("let foo = bar.flatMap { $0.array }")
        ],
        triggeringExamples: [
            Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FlatMapOverMapReduceRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
                memberAccess.name.text == "reduce",
                node.argumentList.count == 2,
                let firstArgument = node.argumentList.first?.expression.as(ArrayExprSyntax.self),
                firstArgument.elements.isEmpty,
                let secondArgument = node.argumentList.last?.expression.as(IdentifierExprSyntax.self),
                secondArgument.identifier.text == "+"
            else {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
