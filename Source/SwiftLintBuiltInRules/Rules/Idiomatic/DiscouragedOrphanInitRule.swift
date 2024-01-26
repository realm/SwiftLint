import SwiftSyntax

@SwiftSyntaxRule
struct DiscouragedOrphanInitRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_orphan_init",
        name: "Discouraged Orphan .init",
        description: "Enforces explicit type declaration to improve readability by avoiding ambiguous .init usage",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOrphanInitRuleExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOrphanInitRuleExamples.triggeringExamples
    )
}

private extension DiscouragedOrphanInitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let expression = node.calledExpression.as(MemberAccessExprSyntax.self),
                  expression.base == nil,
                  expression.period.tokenKind == .period,
                  let name = expression.declName.as(DeclReferenceExprSyntax.self),
                  name.baseName.tokenKind == .keyword(.`init`) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
