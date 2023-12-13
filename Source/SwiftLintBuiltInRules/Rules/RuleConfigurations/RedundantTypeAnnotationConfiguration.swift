struct RedundantTypeAnnotationConfiguration: RuleConfiguration, Equatable {
    typealias Parent = RedundantTypeAnnotationRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_booleans")
    private(set) var ignoreBooleans = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: RedundantTypeAnnotationRule.identifier)
        }
        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
        ignoreBooleans = configuration["ignore_booleans"] as? Bool == true
    }
}
