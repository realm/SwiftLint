import SwiftSyntax

struct IsDisjointRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "is_disjoint",
        name: "Is Disjoint",
        description: "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)"),
            Example("let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)"),
            Example("_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)"),
            Example("_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)")
        ],
        triggeringExamples: [
            Example("_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty"),
            Example("let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension IsDisjointRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.name.text == "isEmpty",
                let firstBase = node.base?.asFunctionCall,
                let firstBaseCalledExpression = firstBase.calledExpression.as(MemberAccessExprSyntax.self),
                firstBaseCalledExpression.name.text == "intersection"
            else {
                return
            }

            violations.append(firstBaseCalledExpression.name.positionAfterSkippingLeadingTrivia)
        }
    }
}
