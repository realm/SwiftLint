struct PrefixedTopLevelConstantConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrefixedTopLevelConstantRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var onlyPrivateMembers = false

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "only_private" => .flag(onlyPrivateMembers)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        onlyPrivateMembers = (configuration["only_private"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
