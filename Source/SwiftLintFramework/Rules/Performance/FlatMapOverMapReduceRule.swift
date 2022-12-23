import SwiftSyntax

struct FlatMapOverMapReduceRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "flatmap_over_map_reduce",
        name: "Flat Map over Map Reduce",
        description: "Prefer `flatMap` over `map` followed by `reduce([], +)`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let foo = bar.map { $0.count }.reduce(0, +)"),
            Example("let foo = bar.flatMap { $0.array }")
        ],
        triggeringExamples: [
            Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FlatMapOverMapReduceRule {
    final class Visitor: ViolationsSyntaxVisitor {
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

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
