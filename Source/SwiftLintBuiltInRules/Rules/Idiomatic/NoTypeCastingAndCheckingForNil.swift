import SwiftSyntax

@SwiftSyntaxRule
struct NoTypeCastingAndCheckingForNilRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "force_is",
        name: "Force Is",
        description: "Force is should be avoided",
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
