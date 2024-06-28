import SwiftSyntax

@SwiftSyntaxRule
struct IsDisjointRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "is_disjoint",
        name: "Is Disjoint",
        description: "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)"),
            Example("let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)"),
            Example("_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)"),
            Example("_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)"),
        ],
        triggeringExamples: [
            Example("_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty"),
            Example("let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty"),
        ]
    )
}

private extension IsDisjointRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "isEmpty",
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.declName.baseName.text == "intersection"
            else {
                return
            }

            violations.append(firstBaseCalledExpression.declName.baseName.positionAfterSkippingLeadingTrivia)
        }
    }
}
