import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct ShorthandOperatorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "shorthand_operator",
        name: "Shorthand Operator",
        description: "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning",
        kind: .style,
        nonTriggeringExamples: #examples([
            "foo -= 1",
            "foo += variable",
            "foo *= bar.method()",
            "self.foo = foo / 1",
            "foo = self.foo + 1",
            "page = ceilf(currentOffset * pageWidth)",
            "foo = aMethod(foo / bar)",
            "foo = aMethod(bar + foo)",
            """
            public func -= (lhs: inout Foo, rhs: Int) {
                lhs = lhs - rhs
            }
            """,
            "var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld",
            "angle = someCheck ? angle : -angle",
            "seconds = seconds * 60 + value",
        ]),
        triggeringExamples: #examples([
            "↓foo = foo * 1",
            "↓foo = foo / aVariable",
            "↓foo = foo - bar.method()",
            "↓foo.aProperty = foo.aProperty - 1",
            "↓self.aProperty = self.aProperty * 1",
            "↓n = n + i / outputLength",
            "↓n = n - i / outputLength",
        ])
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
