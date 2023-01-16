import SwiftSyntax

struct SortedFirstLastRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "sorted_first_last",
        name: "Min or Max over Sorted First or Last",
        description: "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let min = myList.min()\n"),
            Example("let min = myList.min(by: { $0 < $1 })\n"),
            Example("let min = myList.min(by: >)\n"),
            Example("let max = myList.max()\n"),
            Example("let max = myList.max(by: { $0 < $1 })\n"),
            Example("let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last"),
            Example(#"let message = messages.sorted(byKeyPath: "timestamp", ascending: false).first"#),
            Example("myList.sorted().firstIndex(of: key)"),
            Example("myList.sorted().lastIndex(of: key)"),
            Example("myList.sorted().firstIndex(where: someFunction)"),
            Example("myList.sorted().lastIndex(where: someFunction)"),
            Example("myList.sorted().firstIndex { $0 == key }"),
            Example("myList.sorted().lastIndex { $0 == key }")
        ],
        triggeringExamples: [
            Example("↓myList.sorted().first\n"),
            Example("↓myList.sorted(by: { $0.description < $1.description }).first\n"),
            Example("↓myList.sorted(by: >).first\n"),
            Example("↓myList.map { $0 + 1 }.sorted().first\n"),
            Example("↓myList.sorted(by: someFunction).first\n"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first\n"),
            Example("↓myList.sorted().last\n"),
            Example("↓myList.sorted().last?.something()\n"),
            Example("↓myList.sorted(by: { $0.description < $1.description }).last\n"),
            Example("↓myList.map { $0 + 1 }.sorted().last\n"),
            Example("↓myList.sorted(by: someFunction).last\n"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last\n"),
            Example("↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension SortedFirstLastRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.name.text == "first" || node.name.text == "last",
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.name.text == "sorted",
                case let argumentLabels = firstBase.argumentList.map({ $0.label?.text }),
                argumentLabels.isEmpty || argumentLabels == ["by"]
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
