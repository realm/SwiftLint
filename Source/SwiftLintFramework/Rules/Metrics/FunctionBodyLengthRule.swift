public struct FunctionBodyLengthRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 50, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines.",
        kind: .metrics
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        BodyLengthRuleVisitor(kind: .function, file: file, configuration: configuration)
    }
}
