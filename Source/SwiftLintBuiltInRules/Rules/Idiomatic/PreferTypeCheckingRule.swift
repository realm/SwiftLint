import SwiftSyntax

@SwiftSyntaxRule
struct PreferTypeCheckingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_type_checking",
        name: "Prefer Type Checking",
        description: "Prefer `a is X` to `a as? X != nil`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let foo = bar as? Foo"),
            Example("bar is Foo"),
        ],
        triggeringExamples: [
            Example("bar ↓as? Foo != nil")
        ]
    )
}

private extension PreferTypeCheckingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: UnresolvedAsExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .postfixQuestionMark, node.isBeingComparedToNotNil() {
                violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntaxProtocol {
    func isBeingComparedToNotNil() -> Bool {
        guard let parent = parent?.as(ExprListSyntax.self),
              let last = parent.last, last.is(NilLiteralExprSyntax.self) else {
            return false
        }
        return parent.dropLast().last?.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("!=")
    }
}
