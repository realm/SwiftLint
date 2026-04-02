import SwiftSyntax

@SwiftSyntaxRule
struct CombineFlatMapRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "combine_flatmap",
        name: "Combine FlatMap",
        description: "Avoid using Combine's flatMap operator.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("[1, 2, 3].flatMap { $0 }"),
            Example("array.flatMap { $0 }"),
            Example("Combine.map { $0 }")
        ],
        triggeringExamples: [
            Example("Combine.flatMap { $0 }"),
            Example("let transform = Combine.flatMap")
        ]
    )
}

private extension CombineFlatMapRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
                  memberAccess.isCombineFlatMap else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard node.isCombineFlatMap else {
                return
            }

            if let parent = node.parent?.as(FunctionCallExprSyntax.self),
               parent.calledExpression.id == node.id {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension MemberAccessExprSyntax {
    var isCombineFlatMap: Bool {
        guard declName.baseName.text == "flatMap" else {
            return false
        }

        return base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Combine"
    }
}
