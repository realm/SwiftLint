import SwiftSyntax

@SwiftSyntaxRule
struct OperatorFunctionWhitespaceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Functions and operator functions should use a single space between the `func` " +
                     "keyword and their name or operator symbol. For named functions, there must be " +
                     "no whitespace between the function name and the opening parenthesis"
        ,
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
            Example("↓func  name(lhs: A, rhs: A) -> A {}"),      // 2 spaces before
            Example("func ↓name (lhs: A, rhs: A) -> A {}"),      // 1 space after
            Example("↓func  ↓name (lhs: A, rhs: A) -> A {}"),      // 1 space after, 2 spaces before
        ]
    )
}

private extension OperatorFunctionWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            switch node.name.tokenKind {
            case .binaryOperator:
                if !node.name.trailingTrivia.isSingleSpace || !node.funcKeyword.trailingTrivia.isSingleSpace {
                    violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
                }
            case .identifier:
                if !node.funcKeyword.trailingTrivia.isSingleSpace {
                    violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
                }
                if !node.name.trailingTrivia.isEmpty {
                    violations.append(node.name.positionAfterSkippingLeadingTrivia)
                }
            default:
                return
            }
        }
    }
}
