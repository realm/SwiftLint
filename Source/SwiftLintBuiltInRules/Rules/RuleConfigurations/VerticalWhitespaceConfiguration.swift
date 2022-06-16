struct VerticalWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = VerticalWhitespaceRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var maxEmptyLines = 1

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "max_empty_lines" => .integer(maxEmptyLines)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let maxEmptyLines = configuration["max_empty_lines"] as? Int {
            self.maxEmptyLines = maxEmptyLines
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
