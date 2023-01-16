import SwiftSyntax

struct ContainsOverFirstNotNilRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over First not Nil",
        description: "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`.",
        kind: .performance,
        nonTriggeringExamples: ["first", "firstIndex"].flatMap { method in
            return [
                Example("let \(method) = myList.\(method)(where: { $0 % 2 == 0 })\n"),
                Example("let \(method) = myList.\(method) { $0 % 2 == 0 }\n")
            ]
        },
        triggeringExamples: ["first", "firstIndex"].flatMap { method in
            return ["!=", "=="].flatMap { comparison in
                return [
                    Example("↓myList.\(method) { $0 % 2 == 0 } \(comparison) nil\n"),
                    Example("↓myList.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil\n"),
                    Example("↓myList.map { $0 + 1 }.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil\n"),
                    Example("↓myList.\(method)(where: someFunction) \(comparison) nil\n"),
                    Example("↓myList.map { $0 + 1 }.\(method) { $0 % 2 == 0 } \(comparison) nil\n"),
                    Example("(↓myList.\(method) { $0 % 2 == 0 }) \(comparison) nil\n")
                ]
            }
        }
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func preprocess(syntaxTree: SourceFileSyntax) -> SourceFileSyntax? {
        syntaxTree.folded()
    }
}

private extension ContainsOverFirstNotNilRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard
                let operatorNode = node.operatorOperand.as(BinaryOperatorExprSyntax.self),
                operatorNode.operatorToken.tokenKind.isEqualityComparison,
                node.rightOperand.is(NilLiteralExprSyntax.self),
                let first = node.leftOperand.asFunctionCall,
                let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "first" || calledExpression.name.text == "firstIndex"
            else {
                return
            }

            let violation = ReasonedRuleViolation(
                position: first.positionAfterSkippingLeadingTrivia,
                reason: "Prefer `contains` over `\(calledExpression.name.text)(where:) != nil`"
            )
            violations.append(violation)
        }
    }
}
