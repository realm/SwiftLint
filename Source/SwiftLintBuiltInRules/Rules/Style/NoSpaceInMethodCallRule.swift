import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct NoSpaceInMethodCallRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_space_in_method_call",
        name: "No Space in Method Call",
        description: "Don't add a space between the method name and the parentheses",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo()"),
            Example("object.foo()"),
            Example("object.foo(1)"),
            Example("object.foo(value: 1)"),
            Example("object.foo { print($0 }"),
            Example("list.sorted { $0.0 < $1.0 }.map { $0.value }"),
            Example("self.init(rgb: (Int) (colorInt))"),
            Example("""
            Button {
                print("Button tapped")
            } label: {
                Text("Button")
            }
            """),
        ],
        triggeringExamples: [
            Example("foo↓ ()"),
            Example("object.foo↓ ()"),
            Example("object.foo↓ (1)"),
            Example("object.foo↓ (value: 1)"),
            Example("object.foo↓ () {}"),
            Example("object.foo↓     ()"),
            Example("object.foo↓     (value: 1) { x in print(x) }"),
        ],
        corrections: [
            Example("foo↓ ()"): Example("foo()"),
            Example("object.foo↓ ()"): Example("object.foo()"),
            Example("object.foo↓ (1)"): Example("object.foo(1)"),
            Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
            Example("object.foo↓ () {}"): Example("object.foo() {}"),
            Example("object.foo↓     ()"): Example("object.foo()"),
        ]
    )
}

private extension NoSpaceInMethodCallRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.hasNoSpaceInMethodCallViolation else {
                return
            }

            violations.append(node.calledExpression.endPositionBeforeTrailingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.hasNoSpaceInMethodCallViolation else {
                return super.visit(node)
            }

            correctionPositions.append(node.calledExpression.endPositionBeforeTrailingTrivia)

            let newNode = node
                .with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))

            return super.visit(newNode)
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasNoSpaceInMethodCallViolation: Bool {
        leftParen != nil &&
            !calledExpression.is(TupleExprSyntax.self) &&
            calledExpression.trailingTrivia.isNotEmpty
    }
}
