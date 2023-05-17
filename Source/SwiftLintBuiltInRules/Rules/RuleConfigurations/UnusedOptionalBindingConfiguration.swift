struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedOptionalBindingRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var ignoreOptionalTry = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", ignore_optional_try: \(ignoreOptionalTry)"
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
