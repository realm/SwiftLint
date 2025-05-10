import SwiftLintCore

struct FunctionBodyLengthRule: SwiftSyntaxRule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 50, error: 100)

    static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Function bodies should not span too many lines",
        kind: .metrics
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        BodyLengthRuleVisitor(kind: .function, file: file, configuration: configuration)
    }
}
