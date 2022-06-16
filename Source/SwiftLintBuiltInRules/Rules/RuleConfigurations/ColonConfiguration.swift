struct ColonConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ColonRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var flexibleRightSpacing = false
    private(set) var applyToDictionaries = true

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "flexible_right_spacing" => .flag(flexibleRightSpacing)
        "apply_to_dictionaries" => .flag(applyToDictionaries)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        flexibleRightSpacing = configuration["flexible_right_spacing"] as? Bool == true
        applyToDictionaries = configuration["apply_to_dictionaries"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
