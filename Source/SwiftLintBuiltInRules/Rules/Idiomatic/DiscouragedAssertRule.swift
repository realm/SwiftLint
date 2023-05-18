import SwiftSyntax

struct DiscouragedAssertRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
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
            Example(#"XCTAssert(false)"#)
        ],
        triggeringExamples: [
            Example(#"↓assert(false)"#),
            Example(#"↓assert(false, "foobar")"#),
            Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
            Example(#"↓assert(   false    , "foobar")"#)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DiscouragedAssertRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text == "assert",
                  let firstArg = node.argumentList.first,
                  firstArg.label == nil,
                  let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
                  boolExpr.booleanLiteral.tokenKind == .keyword(.false) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
