import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct LegacyRandomRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_random",
        name: "Legacy Random",
        description: "Prefer using `type.random(in:)` over legacy functions",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "Int.random(in: 0..<10)",
            "Double.random(in: 8.6...111.34)",
            "Float.random(in: 0 ..< 1)",
        ]),
        triggeringExamples: #examples([
            "↓arc4random()",
            "↓arc4random_uniform(83)",
            "↓drand48()",
        ])
    )
}

private extension LegacyRandomRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private static let legacyRandomFunctions: Set<String> = [
            "arc4random",
            "arc4random_uniform",
            "drand48",
        ]

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let function = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
               Self.legacyRandomFunctions.contains(function) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
