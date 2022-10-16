public struct ClosureBodyLengthRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 30, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        BodyLengthRuleVisitor(kind: .closure, file: file, configuration: configuration)
    }
}
