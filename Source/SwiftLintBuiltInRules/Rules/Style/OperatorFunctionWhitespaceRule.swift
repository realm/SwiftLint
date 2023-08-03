import SwiftSyntax

struct OperatorFunctionWhitespaceRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Operators should be surrounded by a single whitespace when defining them",
        kind: .style,
        nonTriggeringExamples: [
            "func <| (lhs: Int, rhs: Int) -> Int {}\n",
            "func <|< <A>(lhs: A, rhs: A) -> A {}\n",
            "func abc(lhs: Int, rhs: Int) -> Int {}\n"
        ],
        triggeringExamples: [
            "↓func <|(lhs: Int, rhs: Int) -> Int {}\n",   // no spaces after
            "↓func <|<<A>(lhs: A, rhs: A) -> A {}\n",     // no spaces after
            "↓func <|  (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces after
            "↓func <|<  <A>(lhs: A, rhs: A) -> A {}\n",   // 2 spaces after
            "↓func  <| (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces before
            "↓func  <|< <A>(lhs: A, rhs: A) -> A {}\n"    // 2 spaces before
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension OperatorFunctionWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor {
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
        switch identifier.tokenKind {
        case .binaryOperator:
            return true
        default:
            return false
        }
    }

    var hasWhitespaceViolation: Bool {
        !identifier.trailingTrivia.isSingleSpace || !funcKeyword.trailingTrivia.isSingleSpace
    }
}
