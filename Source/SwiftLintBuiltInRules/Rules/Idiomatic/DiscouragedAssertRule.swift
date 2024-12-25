import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedAssertRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_assert",
        name: "Discouraged Assert",
        description: "Prefer `assertionFailure()` and/or `preconditionFailure()` over `assert(false)`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example(#"assert(true)"#),
            Example(#"assert(true, "foobar")"#),
            Example(#"assert(true, "foobar", file: "toto", line: 42)"#),
            Example(#"assert(false || true)"#),
            Example(#"XCTAssert(false)"#),
        ],
        triggeringExamples: [
            Example(#"↓assert(false)"#),
            Example(#"↓assert(false, "foobar")"#),
            Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
            Example(#"↓assert(   false    , "foobar")"#),
        ]
    )
}

private extension DiscouragedAssertRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "assert",
                  let firstArg = node.arguments.first,
                  firstArg.label == nil,
                  let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
                  boolExpr.literal.tokenKind == .keyword(.false) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
