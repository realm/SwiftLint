import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ClosureBodyLengthRule: Rule {
    private static let defaultWarningThreshold = 30

    var configuration = SeverityLevelsConfiguration<Self>(warning: Self.defaultWarningThreshold, error: 100)

    static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines",
        rationale: """
        "Closure bodies should not span too many lines" says it all.

        Possibly you could refactor your closure code and extract some of it into a function.
        """,
        kind: .metrics,
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples
    )
}

private extension ClosureBodyLengthRule {
    final class Visitor: BodyLengthVisitor<ClosureBodyLengthRule> {
        override func visitPost(_ node: ClosureExprSyntax) {
            registerViolations(
                leftBrace: node.leftBrace,
                rightBrace: node.rightBrace,
                violationNode: node.leftBrace,
                objectName: "Closure"
            )
        }
    }
}
