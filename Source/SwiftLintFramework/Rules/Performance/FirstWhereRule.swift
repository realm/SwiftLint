import SwiftSyntax

struct FirstWhereRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier\n"),
            Example("myList.first(where: { $0 % 2 == 0 })\n"),
            Example("match(pattern: pattern).filter { $0.first == .identifier }\n"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).first\n"),
            Example(#"collection.filter("stringCol = '3'").first"#),
            Example(#"realm?.objects(User.self).filter(NSPredicate(format: "email ==[c] %@", email)).first"#),
            Example(#"if let pause = timeTracker.pauses.filter("beginDate < %@", beginDate).first { print(pause) }"#)
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.first\n"),
            Example("↓myList.filter({ $0 % 2 == 0 }).first\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()\n"),
            Example("↓myList.filter(someFunction).first\n"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.first\n"),
            Example("(↓myList.filter { $0 == 1 }).first\n"),
            Example(#"↓myListOfDict.filter { dict in dict["1"] }.first"#),
            Example(#"↓myListOfDict.filter { $0["someString"] }.first"#)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FirstWhereRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.name.text == "first",
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
