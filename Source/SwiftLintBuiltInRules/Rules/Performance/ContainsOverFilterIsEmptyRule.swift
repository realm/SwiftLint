import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ContainsOverFilterIsEmptyRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contains_over_filter_is_empty",
        name: "Contains over Filter is Empty",
        description: "Prefer `contains` over using `filter(where:).isEmpty`",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
            Example("let result = myList.contains(10)"),
        ],
        triggeringExamples: [
            Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
            Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
            Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty"),
            Example("let result = ↓myList.filter(where: someFunction).isEmpty"),
        ]
    )
}

private extension ContainsOverFilterIsEmptyRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "isEmpty",
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.declName.baseName.text == "filter"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
