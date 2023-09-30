import SwiftLintCore

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable let_var_whitespace

@AutoApply
struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = IndentationWidthRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(
        key: "indentation_width",
        postprocessor: { if $0 < 1 { throw Issue.invalidConfiguration(ruleID: Parent.identifier) } }
    )
    private(set) var indentationWidth = 4
    @ConfigurationElement(key: "include_comments")
    private(set) var includeComments = true
    @ConfigurationElement(key: "include_compiler_directives")
    private(set) var includeCompilerDirectives = true
    @ConfigurationElement(key: "include_multiline_strings")
    private(set) var includeMultilineStrings = true
}
