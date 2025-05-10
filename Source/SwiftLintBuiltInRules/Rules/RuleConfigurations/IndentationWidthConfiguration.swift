import SwiftLintCore

@AutoConfigParser
struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = IndentationWidthRule

    private static let defaultIndentationWidth = 4

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(
        key: "indentation_width",
        postprocessor: {
            if $0 < 1 {
                Issue.invalidConfiguration(ruleID: Parent.identifier).print()
                $0 = Self.defaultIndentationWidth
            }
        }
    )
    private(set) var indentationWidth = 4
    @ConfigurationElement(key: "include_comments")
    private(set) var includeComments = true
    @ConfigurationElement(key: "include_compiler_directives")
    private(set) var includeCompilerDirectives = true
    @ConfigurationElement(key: "include_multiline_strings")
    private(set) var includeMultilineStrings = true
}
