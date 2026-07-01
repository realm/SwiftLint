import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SortedFirstLastRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "sorted_first_last",
        name: "Min or Max over Sorted First or Last",
        description: "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`",
        kind: .performance,
        nonTriggeringExamples: #examples([
            "let min = myList.min()",
            "let min = myList.min(by: { $0 < $1 })",
            "let min = myList.min(by: >)",
            "let max = myList.max()",
            "let max = myList.max(by: { $0 < $1 })",
            "let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last",
            #"let message = messages.sorted(byKeyPath: "timestamp", ascending: false).first"#,
            "myList.sorted().firstIndex(of: key)",
            "myList.sorted().lastIndex(of: key)",
            "myList.sorted().firstIndex(where: someFunction)",
            "myList.sorted().lastIndex(where: someFunction)",
            "myList.sorted().firstIndex { $0 == key }",
            "myList.sorted().lastIndex { $0 == key }",
            "myList.sorted().first(where: someFunction)",
            "myList.sorted().last(where: someFunction)",
            "myList.sorted().first { $0 == key }",
            "myList.sorted().last { $0 == key }",
        ]),
        triggeringExamples: #examples([
            "↓myList.sorted().first",
            "↓myList.sorted(by: { $0.description < $1.description }).first",
            "↓myList.sorted(by: >).first",
            "↓myList.map { $0 + 1 }.sorted().first",
            "↓myList.sorted(by: someFunction).first",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first",
            "↓myList.sorted().last",
            "↓myList.sorted().last?.something()",
            "↓myList.sorted(by: { $0.description < $1.description }).last",
            "↓myList.map { $0 + 1 }.sorted().last",
            "↓myList.sorted(by: someFunction).last",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last",
            "↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last",
        ])
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
