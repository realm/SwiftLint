import SwiftSyntax

struct LegacyRandomRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "legacy_random",
        name: "Legacy Random",
        description: "Prefer using `type.random(in:)` over legacy functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("Int.random(in: 0..<10)\n"),
            Example("Double.random(in: 8.6...111.34)\n"),
            Example("Float.random(in: 0 ..< 1)\n")
        ],
        triggeringExamples: [
            Example("↓arc4random(10)\n"),
            Example("↓arc4random_uniform(83)\n"),
            Example("↓drand48(52)\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension LegacyRandomRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private static let legacyRandomFunctions: Set<String> = [
            "arc4random",
            "arc4random_uniform",
            "drand48"
        ]

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let function = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.withoutTrivia().text,
               Self.legacyRandomFunctions.contains(function) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
