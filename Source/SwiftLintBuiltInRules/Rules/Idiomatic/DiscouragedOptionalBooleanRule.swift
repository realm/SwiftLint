import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedOptionalBooleanRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_optional_boolean",
        name: "Discouraged Optional Boolean",
        description: "Prefer non-optional booleans over optional booleans",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalBooleanRuleExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalBooleanRuleExamples.triggeringExamples
    )
}

private extension DiscouragedOptionalBooleanRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: OptionalTypeSyntax) {
            if node.wrappedType.as(IdentifierTypeSyntax.self)?.typeName == "Bool" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: OptionalChainingExprSyntax) {
            if node.expression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Bool" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let singleArgument = node.arguments.onlyElement,
                singleArgument.expression.is(BooleanLiteralExprSyntax.self),
                let base = calledExpression.base?.as(DeclReferenceExprSyntax.self),
                base.baseName.text == "Optional",
                calledExpression.declName.baseName.text == "some"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
