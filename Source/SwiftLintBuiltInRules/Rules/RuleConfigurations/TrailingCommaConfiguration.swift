struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingCommaRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var mandatoryComma: Bool

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "mandatory_comma" => .flag(mandatoryComma)
    }

    init(mandatoryComma: Bool = false) {
        self.mandatoryComma = mandatoryComma
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        mandatoryComma = (configuration["mandatory_comma"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
