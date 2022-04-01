struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrivateOverFilePrivateRule

    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    var validateExtensions = false

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "validate_extensions" => .flag(validateExtensions)
    }

    // MARK: - RuleConfiguration

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        validateExtensions = configuration["validate_extensions"] as? Bool ?? false
    }
}
