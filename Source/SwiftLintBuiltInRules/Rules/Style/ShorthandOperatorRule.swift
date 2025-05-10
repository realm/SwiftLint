import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct ShorthandOperatorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "shorthand_operator",
        name: "Shorthand Operator",
        description: "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo -= 1"),
            Example("foo += variable"),
            Example("foo *= bar.method()"),
            Example("self.foo = foo / 1"),
            Example("foo = self.foo + 1"),
            Example("page = ceilf(currentOffset * pageWidth)"),
            Example("foo = aMethod(foo / bar)"),
            Example("foo = aMethod(bar + foo)"),
            Example("""
            public func -= (lhs: inout Foo, rhs: Int) {
                lhs = lhs - rhs
            }
            """),
            Example("var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld"),
            Example("angle = someCheck ? angle : -angle"),
            Example("seconds = seconds * 60 + value"),
        ],
        triggeringExamples: [
            Example("↓foo = foo * 1"),
            Example("↓foo = foo / aVariable"),
            Example("↓foo = foo - bar.method()"),
            Example("↓foo.aProperty = foo.aProperty - 1"),
            Example("↓self.aProperty = self.aProperty * 1"),
            Example("↓n = n + i / outputLength"),
            Example("↓n = n - i / outputLength"),
        ]
    )

    fileprivate static let allOperators = ["-", "/", "+", "*"]
}

private extension ShorthandOperatorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.operator.is(AssignmentExprSyntax.self),
                  let rightExpr = node.rightOperand.as(InfixOperatorExprSyntax.self),
                  let binaryOperatorExpr = rightExpr.operator.as(BinaryOperatorExprSyntax.self),
                  ShorthandOperatorRule.allOperators.contains(binaryOperatorExpr.operator.text),
                  node.leftOperand.trimmedDescription == rightExpr.leftOperand.trimmedDescription
            else {
                return
            }

            violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let binaryOperator = node.name.binaryOperator,
               case let shorthandOperators = ShorthandOperatorRule.allOperators.map({ $0 + "=" }),
               shorthandOperators.contains(binaryOperator) {
                return .skipChildren
            }

            return .visitChildren
        }
    }
}

private extension TokenSyntax {
    var binaryOperator: String? {
        switch tokenKind {
        case .binaryOperator(let str):
            return str
        default:
            return nil
        }
    }
}
