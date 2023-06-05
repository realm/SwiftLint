import SwiftSyntax

struct DiscouragedOptionalCollectionRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_optional_collection",
        name: "Discouraged Optional Collection",
        description: "Prefer empty collection over optional collection",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalCollectionExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalCollectionExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DiscouragedOptionalCollectionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: OptionalTypeSyntax) {
            if node.wrappedType.isCollectionType {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: OptionalChainingExprSyntax) {
            if node.expression.isCollectionExpression {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let base = calledExpression.base?.as(IdentifierExprSyntax.self),
                base.identifier.text == "Optional",
                calledExpression.name.text == "some",
                let expression = node.argumentList.first?.expression
            else {
                return
            }

            if expression.isCollectionExpression {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else if let calledExpression = expression.as(FunctionCallExprSyntax.self)?.calledExpression,
                      calledExpression.isCollectionExpression {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension TypeSyntax {
    var isCollectionType: Bool {
        if `is`(ArrayTypeSyntax.self) || `is`(DictionaryTypeSyntax.self) {
            return true
        } else {
            return `as`(SimpleTypeIdentifierSyntax.self)?.name.text == "Set"
        }
    }
}

private extension ExprSyntax {
    var isCollectionExpression: Bool {
        if `is`(ArrayExprSyntax.self) || `is`(DictionaryExprSyntax.self) {
            return true
        } else {
            return `as`(SpecializeExprSyntax.self)?
                .expression
                .as(IdentifierExprSyntax.self)?
                .identifier
                .text == "Set"
        }
    }
}
