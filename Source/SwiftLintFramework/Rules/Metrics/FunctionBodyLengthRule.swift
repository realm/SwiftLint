public struct FunctionBodyLengthRule: SourceKitFreeRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 50, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines.",
        kind: .metrics
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        BodyLengthRuleVisitor(kind: .function, file: file, configuration: configuration)
            .walk(file: file, handler: \.violations)
            .map { violation in
                StyleViolation(ruleDescription: Self.description,
                               severity: violation.severity,
                               location: Location(file: file, position: violation.position),
                               reason: violation.reason)
            }
    }
}
