import SwiftSyntax

struct PreferNimbleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "prefer_nimble",
        name: "Prefer Nimble",
        description: "Prefer Nimble matchers over XCTAssert functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("expect(foo) == 1"),
            Example("expect(foo).to(equal(1))")
        ],
        triggeringExamples: [
            Example("↓XCTAssertTrue(foo)"),
            Example("↓XCTAssertEqual(foo, 2)"),
            Example("↓XCTAssertNotEqual(foo, 2)"),
            Example("↓XCTAssertNil(foo)"),
            Example("↓XCTAssert(foo)"),
            Example("↓XCTAssertGreaterThan(foo, 10)")
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
