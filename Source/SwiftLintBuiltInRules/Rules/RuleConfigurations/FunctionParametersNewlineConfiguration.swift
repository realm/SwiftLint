import SwiftLintCore

@AutoApply
struct FunctionParametersNewlineConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FunctionParametersNewlineRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "leading_paren_on_newline")
    private(set) var leadingParenOnNewline = false
    @ConfigurationElement(key: "trailing_paren_on_newline")
    private(set) var trailingParenOnNewline = false
}
