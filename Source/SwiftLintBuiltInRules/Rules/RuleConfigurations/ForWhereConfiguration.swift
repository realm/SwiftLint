struct ForWhereConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ForWhereRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowForAsFilter = false

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "allow_for_as_filter" => .flag(allowForAsFilter)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowForAsFilter = configuration["allow_for_as_filter"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
