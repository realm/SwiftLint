struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = MultilineParametersRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowsSingleLine = true

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "allowsSingleLine" => .flag(allowsSingleLine)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowsSingleLine = configuration["allows_single_line"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
