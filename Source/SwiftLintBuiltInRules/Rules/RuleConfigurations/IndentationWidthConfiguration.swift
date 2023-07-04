import SwiftLintCore

struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = IndentationWidthRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "indentation_width")
    private(set) var indentationWidth = 4
    @ConfigurationElement(key: "include_comments")
    private(set) var includeComments = true
    @ConfigurationElement(key: "include_compiler_directives")
    private(set) var includeCompilerDirectives = true
    @ConfigurationElement(key: "include_multiline_strings")
    private(set) var includeMultilineStrings = true

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let config = configurationDict[$severityConfiguration] {
            try severityConfiguration.apply(configuration: config)
        }

        if let indentationWidth = configurationDict[$indentationWidth] as? Int, indentationWidth >= 1 {
            self.indentationWidth = indentationWidth
        }

        if let includeComments = configurationDict[$includeComments] as? Bool {
            self.includeComments = includeComments
        }

        if let includeCompilerDirectives = configurationDict[$includeCompilerDirectives] as? Bool {
            self.includeCompilerDirectives = includeCompilerDirectives
        }

        if let includeMultilineStrings = configurationDict[$includeMultilineStrings] as? Bool {
            self.includeMultilineStrings = includeMultilineStrings
        }
    }
}
