import SwiftLintCore

@AutoConfigParser
struct DocCommentParameterConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_returns")
    private(set) var validateReturns = false
    @ConfigurationElement(key: "validate_throws")
    private(set) var validateThrows = false
    @ConfigurationElement(key: "enforce_parameter_syntax")
    private(set) var enforceParameterSyntax = false
}
