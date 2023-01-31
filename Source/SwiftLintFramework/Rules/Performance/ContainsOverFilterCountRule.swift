import SwiftSyntax

struct ContainsOverFilterCountRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "contains_over_filter_count",
        name: "Contains over Filter Count",
        description: "Prefer `contains` over comparing `filter(where:).count` to 0",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1\n"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1\n"),
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 01\n")
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = myList.contains(10)\n")
        ],
        triggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).count \(operation) 0\n"),
                Example("let result = ↓myList.filter { $0 % 2 == 0 }.count \(operation) 0\n"),
                Example("let result = ↓myList.filter(where: someFunction).count \(operation) 0\n")
            ]
        }
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ContainsOverFilterCountRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ExprListSyntax) {
            guard
                node.count == 3,
                let last = node.last?.as(IntegerLiteralExprSyntax.self),
                last.isZero,
                let second = node.dropFirst().first,
                second.firstToken?.tokenKind.isZeroComparison == true,
                let first = node.first?.as(MemberAccessExprSyntax.self),
                first.name.text == "count",
                let firstBase = first.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.name.text == "filter"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TokenKind {
    var isZeroComparison: Bool {
        self == .spacedBinaryOperator("==") ||
            self == .spacedBinaryOperator("!=") ||
            self == .unspacedBinaryOperator("==") ||
            self == .spacedBinaryOperator(">") ||
            self == .unspacedBinaryOperator(">")
    }
}
