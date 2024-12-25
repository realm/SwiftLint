import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct FatalErrorMessageRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            """),
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
            """),
        ]
    )
}

private extension FatalErrorMessageRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
                  expression.baseName.text == "fatalError",
                  node.arguments.isEmptyOrEmptyString else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension LabeledExprListSyntax {
    var isEmptyOrEmptyString: Bool {
        if isEmpty {
            return true
        }
        return count == 1 && first?.expression.as(StringLiteralExprSyntax.self)?.isEmptyString == true
    }
}
