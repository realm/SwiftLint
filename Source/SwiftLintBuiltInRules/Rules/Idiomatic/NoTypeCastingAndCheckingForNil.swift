import SwiftSyntax

@SwiftSyntaxRule
struct NoTypeCastingAndCheckingForNilRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "no_type_casting_and_checking_for_nil",
        name: "No type casting and checking for nil",
        description: "Type casting and then checking for nil should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let dog = dog as? Dog"),
            Example("nonTriggering is Example")
        ],
        triggeringExamples: [
            Example("triggering ↓as? Example != nil")
        ]
    )
}

private extension NoTypeCastingAndCheckingForNilRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ExprListSyntax) {
            guard
                node.castsTypeAndChecksForNil,
                let unresolvedAsExpr = node.dropFirst().first,
                unresolvedAsExpr.is(UnresolvedAsExprSyntax.self) == true
            else {
               return
            }

            violations.append(unresolvedAsExpr.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ExprListSyntax {
    var castsTypeAndChecksForNil: Bool {
        guard
            count == 5,
            first?.is(DeclReferenceExprSyntax.self) == true,
            dropFirst().first?.is(UnresolvedAsExprSyntax.self) == true,
            let binaryOperator = dropFirst(3).first?.as(BinaryOperatorExprSyntax.self),
            binaryOperator.operator.tokenKind == .binaryOperator("!="),
            last?.is(NilLiteralExprSyntax.self) == true
        else {
            return false
        }

        return true
    }
}
