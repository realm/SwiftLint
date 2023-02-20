import SwiftSyntax

struct ShorthandOperatorRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "shorthand_operator",
        name: "Shorthand Operator",
        description: "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning",
        kind: .style,
        nonTriggeringExamples: allOperators.flatMap { operation in
            [
                Example("foo \(operation)= 1"),
                Example("foo \(operation)= variable"),
                Example("foo \(operation)= bar.method()"),
                Example("self.foo = foo \(operation) 1"),
                Example("foo = self.foo \(operation) 1"),
                Example("page = ceilf(currentOffset \(operation) pageWidth)"),
                Example("foo = aMethod(foo \(operation) bar)"),
                Example("foo = aMethod(bar \(operation) foo)"),
                Example("""
                public func \(operation)= (lhs: inout Foo, rhs: Int) {
                    lhs = lhs \(operation) rhs
                }
                """)
            ]
        } + [
            Example("var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld"),
            Example("angle = someCheck ? angle : -angle"),
            Example("seconds = seconds * 60 + value")
        ],
        triggeringExamples: allOperators.flatMap { operation in
            [
                Example("↓foo = foo \(operation) 1\n"),
                Example("↓foo = foo \(operation) aVariable\n"),
                Example("↓foo = foo \(operation) bar.method()\n"),
                Example("↓foo.aProperty = foo.aProperty \(operation) 1\n"),
                Example("↓self.aProperty = self.aProperty \(operation) 1\n")
            ]
        } + [
            Example("↓n = n + i / outputLength"),
            Example("↓n = n - i / outputLength")
        ]
    )

    fileprivate static let allOperators = ["-", "/", "+", "*"]

    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
        file.foldedSyntaxTree
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ShorthandOperatorRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.operatorOperand.is(AssignmentExprSyntax.self),
                  let rightExpr = node.rightOperand.as(InfixOperatorExprSyntax.self),
                  let binaryOperatorExpr = rightExpr.operatorOperand.as(BinaryOperatorExprSyntax.self),
                  ShorthandOperatorRule.allOperators.contains(binaryOperatorExpr.operatorToken.text),
                  node.leftOperand.trimmedDescription == rightExpr.leftOperand.trimmedDescription
            else {
                return
            }

            violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let binaryOperator = node.identifier.binaryOperator,
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
