struct TrailingWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingWhitespaceRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var ignoresEmptyLines = false
    private(set) var ignoresComments = true

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "ignores_empty_lines" => .flag(ignoresEmptyLines)
        "ignores_comments" => .flag(ignoresComments)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        ignoresEmptyLines = (configuration["ignores_empty_lines"] as? Bool == true)
        ignoresComments = (configuration["ignores_comments"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
