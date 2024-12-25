import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SortedFirstLastRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "sorted_first_last",
        name: "Min or Max over Sorted First or Last",
        description: "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let min = myList.min()"),
            Example("let min = myList.min(by: { $0 < $1 })"),
            Example("let min = myList.min(by: >)"),
            Example("let max = myList.max()"),
            Example("let max = myList.max(by: { $0 < $1 })"),
            Example("let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last"),
            Example(#"let message = messages.sorted(byKeyPath: "timestamp", ascending: false).first"#),
            Example("myList.sorted().firstIndex(of: key)"),
            Example("myList.sorted().lastIndex(of: key)"),
            Example("myList.sorted().firstIndex(where: someFunction)"),
            Example("myList.sorted().lastIndex(where: someFunction)"),
            Example("myList.sorted().firstIndex { $0 == key }"),
            Example("myList.sorted().lastIndex { $0 == key }"),
            Example("myList.sorted().first(where: someFunction)"),
            Example("myList.sorted().last(where: someFunction)"),
            Example("myList.sorted().first { $0 == key }"),
            Example("myList.sorted().last { $0 == key }"),
        ],
        triggeringExamples: [
            Example("↓myList.sorted().first"),
            Example("↓myList.sorted(by: { $0.description < $1.description }).first"),
            Example("↓myList.sorted(by: >).first"),
            Example("↓myList.map { $0 + 1 }.sorted().first"),
            Example("↓myList.sorted(by: someFunction).first"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first"),
            Example("↓myList.sorted().last"),
            Example("↓myList.sorted().last?.something()"),
            Example("↓myList.sorted(by: { $0.description < $1.description }).last"),
            Example("↓myList.map { $0 + 1 }.sorted().last"),
            Example("↓myList.sorted(by: someFunction).last"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last"),
        ]
    )
}

private extension SortedFirstLastRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "first" || node.declName.baseName.text == "last",
                node.parent?.is(FunctionCallExprSyntax.self) != true,
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.declName.baseName.text == "sorted",
                case let argumentLabels = firstBase.arguments.map({ $0.label?.text }),
                argumentLabels.isEmpty || argumentLabels == ["by"]
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
