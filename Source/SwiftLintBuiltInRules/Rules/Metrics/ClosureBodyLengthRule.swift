struct ClosureBodyLengthRule: OptInRule, SwiftSyntaxRule {
    let defaultWarningThreshold = 30
    var configuration = SeverityLevelsConfiguration<Self>(warning: defaultWarningThreshold, error: 100)

    static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines",
        rationale: """
        "Closure bodies should not span too many lines" says it all.

        Possibly you could refactor your closure code and extract some of it into a function.

        Many installations, including SwiftLint's, increase the default warning value from \(defaultWarningThreshold) \
        to 50, which is a bit more permissive.
        """,
        kind: .metrics,
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        BodyLengthRuleVisitor(kind: .closure, file: file, configuration: configuration)
    }
}
