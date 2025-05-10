import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PreferNimbleRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_nimble",
        name: "Prefer Nimble",
        description: "Prefer Nimble matchers over XCTAssert functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("expect(foo) == 1"),
            Example("expect(foo).to(equal(1))"),
        ],
        triggeringExamples: [
            Example("↓XCTAssertTrue(foo)"),
            Example("↓XCTAssertEqual(foo, 2)"),
            Example("↓XCTAssertNotEqual(foo, 2)"),
            Example("↓XCTAssertNil(foo)"),
            Example("↓XCTAssert(foo)"),
            Example("↓XCTAssertGreaterThan(foo, 10)"),
        ]
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
