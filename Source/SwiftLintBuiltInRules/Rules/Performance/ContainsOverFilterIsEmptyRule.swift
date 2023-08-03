import SwiftSyntax

struct ContainsOverFilterIsEmptyRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contains_over_filter_is_empty",
        name: "Contains over Filter is Empty",
        description: "Prefer `contains` over using `filter(where:).isEmpty`",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                "let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1\n",
                "let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1\n"
            ]
        } + [
            "let result = myList.contains(where: { $0 % 2 == 0 })\n",
            "let result = !myList.contains(where: { $0 % 2 == 0 })\n",
            "let result = myList.contains(10)\n"
        ],
        triggeringExamples: [
            "let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n",
            "let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n",
            "let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty\n",
            "let result = ↓myList.filter(where: someFunction).isEmpty\n"
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ContainsOverFilterIsEmptyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.name.text == "isEmpty",
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.name.text == "filter"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
