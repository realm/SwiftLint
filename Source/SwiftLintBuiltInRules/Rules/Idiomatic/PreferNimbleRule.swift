import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PreferNimbleRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_nimble",
        name: "Prefer Nimble",
        description: "Prefer Nimble matchers over XCTAssert functions",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "expect(foo) == 1",
            "expect(foo).to(equal(1))",
        ]),
        triggeringExamples: #examples([
            "↓XCTAssertTrue(foo)",
            "↓XCTAssertEqual(foo, 2)",
            "↓XCTAssertNotEqual(foo, 2)",
            "↓XCTAssertNil(foo)",
            "↓XCTAssert(foo)",
            "↓XCTAssertGreaterThan(foo, 10)",
        ])
    )
}

private extension PreferNimbleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               expr.baseName.text.starts(with: "XCTAssert") {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
