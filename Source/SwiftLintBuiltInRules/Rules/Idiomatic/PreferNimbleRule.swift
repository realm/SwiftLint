import SwiftSyntax

struct PreferNimbleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_nimble",
        name: "Prefer Nimble",
        description: "Prefer Nimble matchers over XCTAssert functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "expect(foo) == 1",
            "expect(foo).to(equal(1))"
        ],
        triggeringExamples: [
            "↓XCTAssertTrue(foo)",
            "↓XCTAssertEqual(foo, 2)",
            "↓XCTAssertNotEqual(foo, 2)",
            "↓XCTAssertNil(foo)",
            "↓XCTAssert(foo)",
            "↓XCTAssertGreaterThan(foo, 10)"
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PreferNimbleRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let expr = node.calledExpression.as(IdentifierExprSyntax.self),
               expr.identifier.text.starts(with: "XCTAssert") {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
