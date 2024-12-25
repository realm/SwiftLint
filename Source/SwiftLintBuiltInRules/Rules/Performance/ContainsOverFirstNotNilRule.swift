import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct ContainsOverFirstNotNilRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over First not Nil",
        description: "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`.",
        kind: .performance,
        nonTriggeringExamples: ["first", "firstIndex"].flatMap { method in
            [
                Example("let \(method) = myList.\(method)(where: { $0 % 2 == 0 })"),
                Example("let \(method) = myList.\(method) { $0 % 2 == 0 }"),
            ]
        },
        triggeringExamples: ["first", "firstIndex"].flatMap { method in
            ["!=", "=="].flatMap { comparison in
                [
                    Example("↓myList.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("↓myList.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil"),
                    Example("↓myList.map { $0 + 1 }.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil"),
                    Example("↓myList.\(method)(where: someFunction) \(comparison) nil"),
                    Example("↓myList.map { $0 + 1 }.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("(↓myList.\(method) { $0 % 2 == 0 }) \(comparison) nil"),
                ]
            }
        }
    )
}

private extension ContainsOverFirstNotNilRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
                  operatorNode.operator.tokenKind.isEqualityComparison,
                  node.rightOperand.is(NilLiteralExprSyntax.self),
                  let first = node.leftOperand.asFunctionCall,
                  let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                  ["first", "firstIndex"].contains(calledExpression.declName.baseName.text) else {
                return
            }

            let violation = ReasonedRuleViolation(
                position: first.positionAfterSkippingLeadingTrivia,
                reason: "Prefer `contains` over `\(calledExpression.declName.baseName.text)(where:) != nil`"
            )
            violations.append(violation)
        }
    }
}
