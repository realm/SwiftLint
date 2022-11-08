import SwiftSyntax

struct DiscouragedOptionalBooleanRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "discouraged_optional_boolean",
        name: "Discouraged Optional Boolean",
        description: "Prefer non-optional booleans over optional booleans.",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalBooleanRuleExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalBooleanRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DiscouragedOptionalBooleanRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: OptionalTypeSyntax) {
            if node.wrappedType.as(SimpleTypeIdentifierSyntax.self)?.typeName == "Bool" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: OptionalChainingExprSyntax) {
            if node.expression.as(IdentifierExprSyntax.self)?.identifier.text == "Bool" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let singleArgument = node.argumentList.onlyElement,
                singleArgument.expression.is(BooleanLiteralExprSyntax.self),
                let base = calledExpression.base?.as(IdentifierExprSyntax.self),
                base.identifier.text == "Optional",
                calledExpression.name.text == "some"
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
