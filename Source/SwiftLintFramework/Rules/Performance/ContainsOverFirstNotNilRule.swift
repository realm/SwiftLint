import SwiftSyntax

public struct ContainsOverFirstNotNilRule: SourceKitFreeRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over first not nil",
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree.folded() else {
            return []
        }

        return Visitor(viewMode: .sourceAccurate)
            .walk(tree: tree, handler: \.violations)
            .map { violation in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, position: violation.position),
                               reason: violation.reason)
            }
    }
}

private extension ContainsOverFirstNotNilRule {
    struct Violation {
        let position: AbsolutePosition
        let reason: String
    }

    final class Visitor: SyntaxVisitor {
        private(set) var violations: [Violation] = []

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

            let violation = Violation(
                position: first.positionAfterSkippingLeadingTrivia,
                reason: "Prefer `contains` over `\(calledExpression.name.text)(where:) != nil`"
            )
            violations.append(violation)
        }
    }
}
