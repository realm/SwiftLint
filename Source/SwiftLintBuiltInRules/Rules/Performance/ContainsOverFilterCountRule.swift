import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ContainsOverFilterCountRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contains_over_filter_count",
        name: "Contains over Filter Count",
        description: "Prefer `contains` over comparing `filter(where:).count` to 0",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            #examples([
                "let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1",
                "let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1",
                "let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 01",
            ])
        } + #examples([
            "let result = myList.contains(where: { $0 % 2 == 0 })",
            "let result = !myList.contains(where: { $0 % 2 == 0 })",
            "let result = myList.contains(10)",
        ]),
        triggeringExamples: [">", "==", "!="].flatMap { operation in
            #examples([
                "let result = ↓myList.filter(where: { $0 % 2 == 0 }).count \(operation) 0",
                "let result = ↓myList.filter { $0 % 2 == 0 }.count \(operation) 0",
                "let result = ↓myList.filter(where: someFunction).count \(operation) 0",
            ])
        }
    )
}

private extension ContainsOverFilterCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ExprListSyntax) {
            guard
                node.count == 3,
                let last = node.last?.as(IntegerLiteralExprSyntax.self),
                last.isZero,
                let second = node.dropFirst().first,
                second.firstToken(viewMode: .sourceAccurate)?.tokenKind.isZeroComparison == true,
                let first = node.first?.as(MemberAccessExprSyntax.self),
                first.declName.baseName.text == "count",
                let firstBase = first.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.declName.baseName.text == "filter"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TokenKind {
    var isZeroComparison: Bool {
        self == .binaryOperator("==") ||
            self == .binaryOperator("!=") ||
            self == .binaryOperator(">")
    }
}
