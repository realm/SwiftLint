import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct RedundantNilCoalescingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil" +
            ", coalescing operator with nil as rhs is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?; myVar ?? 0")
        ],
        triggeringExamples: [
            Example("var myVar: Int? = nil; myVar ↓?? nil")
        ],
        corrections: [
            Example("var myVar: Int? = nil; let foo = myVar ↓?? nil"):
                Example("var myVar: Int? = nil; let foo = myVar"),
        ]
    )
}

private extension RedundantNilCoalescingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            if node.tokenKind.isNilCoalescingOperator,
               node.nextToken(viewMode: .sourceAccurate)?.tokenKind == .keyword(.nil) {
                violations.append(node.position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard
                node.count > 2,
                let lastExpression = node.last,
                lastExpression.is(NilLiteralExprSyntax.self),
                let secondToLastExpression = node.dropLast().last?.as(BinaryOperatorExprSyntax.self),
                secondToLastExpression.operator.tokenKind.isNilCoalescingOperator
            else {
                return super.visit(node)
            }

            let newNode = ExprListSyntax(node.dropLast(2)).with(\.trailingTrivia, [])
            correctionPositions.append(secondToLastExpression.operator.positionAfterSkippingLeadingTrivia)
            return super.visit(newNode)
        }
    }
}

private extension TokenKind {
    var isNilCoalescingOperator: Bool {
        self == .binaryOperator("??")
    }
}
