import SwiftSyntax

public struct XCTFailMessageRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xctfail_message",
        name: "XCTFail Message",
        description: "An XCTFail call should include a description of the assertion.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func testFoo() {
              XCTFail("bar")
            }
            """),
            Example("""
            func testFoo() {
              XCTFail(bar)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func testFoo() {
              ↓XCTFail()
            }
            """),
            Example("""
            func testFoo() {
              ↓XCTFail("")
            }
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension XCTFailMessageRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let expression = node.calledExpression.as(IdentifierExprSyntax.self),
                expression.identifier.text == "XCTFail",
                node.argumentList.isEmptyOrEmptyString
            else {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TupleExprElementListSyntax {
    var isEmptyOrEmptyString: Bool {
        if isEmpty {
            return true
        }
        return count == 1 && first?.expression.as(StringLiteralExprSyntax.self)?.isEmpty == true
    }
}

private extension StringLiteralExprSyntax {
    var isEmpty: Bool {
        segments.count == 1 && segments.first?.contentLength == .zero
    }
}
