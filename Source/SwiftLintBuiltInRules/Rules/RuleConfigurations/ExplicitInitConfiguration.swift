struct ExplicitInitConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ExplicitInitRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_bare_init")
    private(set) var includeBareInit = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let includeBareInit = configuration[$includeBareInit] as? Bool {
            self.includeBareInit = includeBareInit
        }
    }
}
