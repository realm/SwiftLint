import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, optIn: true)
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
            Example("let a = b ?? nil // swiftlint:disable:this redundant_nil_coalescing"):
                Example("let a = b ?? nil // swiftlint:disable:this redundant_nil_coalescing"),
        ]
    )
}

private extension RedundantNilCoalescingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            if node.operator.isNilCoalescingOperator, node.rightOperand.is(NilLiteralExprSyntax.self) {
                violations.append(node.operator.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard node.operator.isNilCoalescingOperator,
                  node.rightOperand.is(NilLiteralExprSyntax.self) else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.leftOperand.with(\.trailingTrivia, []))
        }
    }
}

private extension ExprSyntax {
    var isNilCoalescingOperator: Bool {
        `as`(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("??")
    }
}
