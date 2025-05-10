import SwiftSyntax

@SwiftSyntaxRule
struct OperatorFunctionWhitespaceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Operators should be surrounded by a single whitespace when defining them",
        kind: .style,
        nonTriggeringExamples: [
            Example("func <| (lhs: Int, rhs: Int) -> Int {}"),
            Example("func <|< <A>(lhs: A, rhs: A) -> A {}"),
            Example("func abc(lhs: Int, rhs: Int) -> Int {}"),
        ],
        triggeringExamples: [
            Example("↓func <|(lhs: Int, rhs: Int) -> Int {}"),   // no spaces after
            Example("↓func <|<<A>(lhs: A, rhs: A) -> A {}"),     // no spaces after
            Example("↓func <|  (lhs: Int, rhs: Int) -> Int {}"), // 2 spaces after
            Example("↓func <|<  <A>(lhs: A, rhs: A) -> A {}"),   // 2 spaces after
            Example("↓func  <| (lhs: Int, rhs: Int) -> Int {}"), // 2 spaces before
            Example("↓func  <|< <A>(lhs: A, rhs: A) -> A {}"),   // 2 spaces before
        ]
    )
}

private extension OperatorFunctionWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isOperatorDeclaration, node.hasWhitespaceViolation else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var isOperatorDeclaration: Bool {
        switch name.tokenKind {
        case .binaryOperator:
            return true
        default:
            return false
        }
    }

    var hasWhitespaceViolation: Bool {
        !name.trailingTrivia.isSingleSpace || !funcKeyword.trailingTrivia.isSingleSpace
    }
}
