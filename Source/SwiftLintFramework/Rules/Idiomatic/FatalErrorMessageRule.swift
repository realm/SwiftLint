import SwiftSyntax

struct FatalErrorMessageRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "fatal_error_message",
        name: "Fatal Error Message",
        description: "A fatalError call should have a message",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func foo() {
              fatalError("Foo")
            }
            """),
            Example("""
            func foo() {
              fatalError(x)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func foo() {
              ↓fatalError("")
            }
            """),
            Example("""
            func foo() {
              ↓fatalError()
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FatalErrorMessageRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let expression = node.calledExpression.as(IdentifierExprSyntax.self),
                  expression.identifier.withoutTrivia().text == "fatalError",
                node.argumentList.isEmptyOrEmptyString else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TupleExprElementListSyntax {
    var isEmptyOrEmptyString: Bool {
        if isEmpty {
            return true
        }
        return count == 1 && first?.expression.as(StringLiteralExprSyntax.self)?.isEmptyString == true
    }
}
