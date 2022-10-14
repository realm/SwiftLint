public struct ClosureBodyLengthRule: OptInRule, SourceKitFreeRule, ConfigurationProviderRule {
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        BodyLengthRuleVisitor(kind: .closure, file: file, configuration: configuration)
            .walk(file: file, handler: \.violations)
            .map { violation in
                StyleViolation(ruleDescription: Self.description,
                               severity: violation.severity,
                               location: Location(file: file, position: violation.position),
                               reason: violation.reason)
            }
    }
}
