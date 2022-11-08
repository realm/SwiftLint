import SwiftSyntax

struct ContainsOverFilterIsEmptyRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "contains_over_filter_is_empty",
        name: "Contains Over Filter Is Empty",
        description: "Prefer `contains` over using `filter(where:).isEmpty`",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1\n"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1\n")
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = myList.contains(10)\n")
        ],
        triggeringExamples: [
            Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n"),
            Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n"),
            Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty\n"),
            Example("let result = ↓myList.filter(where: someFunction).isEmpty\n")
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
