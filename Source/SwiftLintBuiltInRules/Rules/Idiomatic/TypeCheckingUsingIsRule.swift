import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true)
struct TypeCheckingUsingIsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "type_checking_using_is",
        name: "Type checking using is",
        description: "Type checking using is should be preferred",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let dog = dog as? Dog"),
            Example("nonTriggering is Example"),
            Example("""
            if a is Dog {
                doSomeThing()
            }
            """),
            Example("""
            if let dog = dog as? Dog {
                dog.run()
            }
            """)
        ],
        triggeringExamples: [
            Example("triggering ↓as? Example != nil"),
            Example("""
            if a ↓as? Dog != nil {
                doSomeThing()
            }
            """)
        ],
        corrections: [
            Example("triggering ↓as? Example != nil"): Example("triggering is Example"),
            Example("""
            if a ↓as? Dog != nil {
                doSomeThing()
            }
            """): Example("""
            if a is Dog {
                doSomeThing()
            }
            """)
        ]
    )
}

private extension TypeCheckingUsingIsRule {
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
    
    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard
                node.castsTypeAndChecksForNil,
                let unresolvedAsExpr = node.dropFirst().first,
                let indexUnresolvedAsExpr = node.index(of: unresolvedAsExpr),
                let typeExpr = node.dropFirst(2).first
            else {
                return super.visit(node)
            }
            correctionPositions.append(unresolvedAsExpr.positionAfterSkippingLeadingTrivia)
            let elements = node
                .with(
                    \.[indexUnresolvedAsExpr],
                     "is \(typeExpr.trimmed)"
                )
                .dropLast(3)
            let newNode = ExprListSyntax(elements)
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
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
