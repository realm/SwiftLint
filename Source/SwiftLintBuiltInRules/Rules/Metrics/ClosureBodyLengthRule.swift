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
    final class Visitor: BodyLengthVisitor<ConfigurationType> {
        private lazy var skipThreshold: Int = {
            let severityConfiguration = configuration.severityConfiguration
            return min(severityConfiguration.warning, severityConfiguration.error ?? severityConfiguration.warning)
        }()

        override func visitPost(_ node: ClosureExprSyntax) {
            let leftBraceLine = locationConverter.location(for: node.leftBrace.positionAfterSkippingLeadingTrivia).line
            let rightBraceLine = locationConverter.location(
                for: node.rightBrace.positionAfterSkippingLeadingTrivia
            ).line
            // The body line count ignoring comments and whitespace can never exceed the physical number of
            // lines spanned by the braces. Skip the expensive body line computation when even that upper
            // bound cannot trigger a violation.
            let startLine = min(leftBraceLine + 1, rightBraceLine - 1)
            let endLine = max(rightBraceLine - 1, leftBraceLine + 1)
            if 1 + endLine - startLine <= skipThreshold {
                return
            }
            registerViolations(
                leftBrace: node.leftBrace,
                rightBrace: node.rightBrace,
                violationNode: node.leftBrace,
                objectName: "Closure"
            )
        }
    }
}
