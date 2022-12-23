struct FunctionBodyLengthRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityLevelsConfiguration(warning: 50, error: 100)

    init() {}

    static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Function bodies should not span too many lines",
        kind: .metrics
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        BodyLengthRuleVisitor(kind: .function, file: file, configuration: configuration)
    }
}
