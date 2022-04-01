struct TrailingClosureConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingClosureRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var onlySingleMutedParameter: Bool

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "only_single_muted_parameter" => .flag(onlySingleMutedParameter)
    }

    init(onlySingleMutedParameter: Bool = false) {
        self.onlySingleMutedParameter = onlySingleMutedParameter
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        onlySingleMutedParameter = (configuration["only_single_muted_parameter"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
