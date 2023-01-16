import SwiftSyntax

struct LastWhereRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "last_where",
        name: "Last Where",
        description: "Prefer using `.last(where:)` over `.filter { }.last` in collections",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier\n"),
            Example("myList.last(where: { $0 % 2 == 0 })\n"),
            Example("match(pattern: pattern).filter { $0.last == .identifier }\n"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).last\n"),
            Example(#"collection.filter("stringCol = '3'").last"#)
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.last\n"),
            Example("↓myList.filter({ $0 % 2 == 0 }).last\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()\n"),
            Example("↓myList.filter(someFunction).last\n"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.last\n"),
            Example("(↓myList.filter { $0 == 1 }).last\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension LastWhereRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.name.text == "last",
                let functionCall = node.base?.asFunctionCall,
                let calledExpression = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "filter",
                !functionCall.argumentList.contains(where: \.expression.shouldSkip)
            else {
                return
            }

            violations.append(functionCall.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ExprSyntax {
    var shouldSkip: Bool {
        if self.is(StringLiteralExprSyntax.self) {
            return true
        } else if let functionCall = self.as(FunctionCallExprSyntax.self),
                  let calledExpression = functionCall.calledExpression.as(IdentifierExprSyntax.self),
                  calledExpression.identifier.text == "NSPredicate" {
            return true
        } else {
            return false
        }
    }
}
