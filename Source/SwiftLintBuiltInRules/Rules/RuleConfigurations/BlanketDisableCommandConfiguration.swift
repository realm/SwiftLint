struct BlanketDisableCommandConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = BlanketDisableCommandRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowedRuleIdentifiers: Set<String> = [
        "file_header",
        "file_length",
        "file_name",
        "file_name_no_space",
        "single_test_class"
    ]
    private(set) var alwaysBlanketDisableRuleIdentifiers: Set<String> = []

    var consoleDescription: String {
        "severity: \(severityConfiguration.consoleDescription)" +
        ", allowed_rules: \(allowedRuleIdentifiers.sorted())" +
        ", always_blanket_disable: \(alwaysBlanketDisableRuleIdentifiers.sorted())"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedRuleIdentifiers = configuration["allowed_rules"] as? [String] {
            self.allowedRuleIdentifiers = Set(allowedRuleIdentifiers)
        }

        if let alwaysBlanketDisableRuleIdentifiers = configuration["always_blanket_disable"] as? [String] {
            self.alwaysBlanketDisableRuleIdentifiers = Set(alwaysBlanketDisableRuleIdentifiers)
        }
    }

    var severity: ViolationSeverity {
        severityConfiguration.severity
    }
}
