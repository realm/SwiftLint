struct IndentationWidthConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = IndentationWidthRule

    var consoleDescription: String {
        return "severity: \("severity: \(severityConfiguration.consoleDescription)"), "
            + "indentation_width: \(indentationWidth), "
            + "include_comments: \(includeComments), "
            + "include_compiler_directives: \(includeCompilerDirectives)"
            + "include_multiline_strings: \(includeMultilineStrings)"
    }

    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    private(set) var indentationWidth = 4
    private(set) var includeComments = true
    private(set) var includeCompilerDirectives = true
    private(set) var includeMultilineStrings = true

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let config = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: config)
        }

        if let indentationWidth = configurationDict["indentation_width"] as? Int, indentationWidth >= 1 {
            self.indentationWidth = indentationWidth
        }

        if let includeComments = configurationDict["include_comments"] as? Bool {
            self.includeComments = includeComments
        }

        if let includeCompilerDirectives = configurationDict["include_compiler_directives"] as? Bool {
            self.includeCompilerDirectives = includeCompilerDirectives
        }

        if let includeMultilineStrings = configurationDict["include_multiline_strings"] as? Bool {
            self.includeMultilineStrings = includeMultilineStrings
        }
    }
}
