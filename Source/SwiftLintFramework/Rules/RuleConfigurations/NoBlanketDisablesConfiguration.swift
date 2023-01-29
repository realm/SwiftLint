public struct NoBlanketDisablesConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var allowedRuleIdentifiers: Set<String> = ["file_length", "single_test_class"]

    public var consoleDescription: String {
        "severity: \(severityConfiguration.consoleDescription)" +
        ", allowed_rules: \(allowedRuleIdentifiers.sorted())"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedRuleIdentifiers = configuration["allowed_rules"] as? [String] {
            self.allowedRuleIdentifiers = Set(allowedRuleIdentifiers)
        }
    }

    public var severity: ViolationSeverity {
        severityConfiguration.severity
    }
}
