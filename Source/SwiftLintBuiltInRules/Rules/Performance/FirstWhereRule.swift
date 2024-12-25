import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct FirstWhereRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier"),
            Example("myList.first(where: { $0 % 2 == 0 })"),
            Example("match(pattern: pattern).filter { $0.first == .identifier }"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).first"),
            Example(#"collection.filter("stringCol = '3'").first"#),
            Example(#"realm?.objects(User.self).filter(NSPredicate(format: "email ==[c] %@", email)).first"#),
            Example(#"if let pause = timeTracker.pauses.filter("beginDate < %@", beginDate).first { print(pause) }"#),
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.first"),
            Example("↓myList.filter({ $0 % 2 == 0 }).first"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()"),
            Example("↓myList.filter(someFunction).first"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.first"),
            Example("(↓myList.filter { $0 == 1 }).first"),
            Example(#"↓myListOfDict.filter { dict in dict["1"] }.first"#),
            Example(#"↓myListOfDict.filter { $0["someString"] }.first"#),
        ]
    )
}

private extension FirstWhereRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "first",
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
