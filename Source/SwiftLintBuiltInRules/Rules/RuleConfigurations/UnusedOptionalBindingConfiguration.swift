struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedOptionalBindingRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var ignoreOptionalTry = false

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "ignore_optional_try" => .flag(ignoreOptionalTry)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let ignoreOptionalTry = configuration["ignore_optional_try"] as? Bool {
            self.ignoreOptionalTry = ignoreOptionalTry
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
