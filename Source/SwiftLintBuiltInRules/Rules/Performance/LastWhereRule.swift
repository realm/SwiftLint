import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct LastWhereRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "last_where",
        name: "Last Where",
        description: "Prefer using `.last(where:)` over `.filter { }.last` in collections",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier"),
            Example("myList.last(where: { $0 % 2 == 0 })"),
            Example("match(pattern: pattern).filter { $0.last == .identifier }"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).last"),
            Example(#"collection.filter("stringCol = '3'").last"#),
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.last"),
            Example("↓myList.filter({ $0 % 2 == 0 }).last"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()"),
            Example("↓myList.filter(someFunction).last"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.last"),
            Example("(↓myList.filter { $0 == 1 }).last"),
        ]
    )
}

private extension LastWhereRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "last",
                let functionCall = node.base?.asFunctionCall,
                let calledExpression = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.declName.baseName.text == "filter",
                !functionCall.arguments.contains(where: \.expression.shouldSkip)
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
        }
        if let functionCall = self.as(FunctionCallExprSyntax.self),
                  let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
                  calledExpression.baseName.text == "NSPredicate" {
            return true
        }
        return false
    }
}
