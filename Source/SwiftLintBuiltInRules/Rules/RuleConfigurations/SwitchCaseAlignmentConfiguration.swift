struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = SwitchCaseAlignmentRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var indentedCases = false

    init() {}

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "indented_cases" => .flag(indentedCases)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        indentedCases = configuration["indented_cases"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
