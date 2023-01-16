import SwiftSyntax

struct OperatorFunctionWhitespaceRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Operators should be surrounded by a single whitespace when defining them",
        kind: .style,
        nonTriggeringExamples: [
            Example("func <| (lhs: Int, rhs: Int) -> Int {}\n"),
            Example("func <|< <A>(lhs: A, rhs: A) -> A {}\n"),
            Example("func abc(lhs: Int, rhs: Int) -> Int {}\n")
        ],
        triggeringExamples: [
            Example("↓func <|(lhs: Int, rhs: Int) -> Int {}\n"),   // no spaces after
            Example("↓func <|<<A>(lhs: A, rhs: A) -> A {}\n"),     // no spaces after
            Example("↓func <|  (lhs: Int, rhs: Int) -> Int {}\n"), // 2 spaces after
            Example("↓func <|<  <A>(lhs: A, rhs: A) -> A {}\n"),   // 2 spaces after
            Example("↓func  <| (lhs: Int, rhs: Int) -> Int {}\n"), // 2 spaces before
            Example("↓func  <|< <A>(lhs: A, rhs: A) -> A {}\n")    // 2 spaces before
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
        case .spacedBinaryOperator, .unspacedBinaryOperator:
            return true
        default:
            return false
        }
    }

    var hasWhitespaceViolation: Bool {
        !identifier.trailingTrivia.isSingleSpace || !funcKeyword.trailingTrivia.isSingleSpace
    }
}
