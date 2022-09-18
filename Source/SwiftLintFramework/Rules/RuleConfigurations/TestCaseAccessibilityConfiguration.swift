public struct TestCaseAccessibilityConfiguration: RuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var allowedPrefixes: Set<String> = []
    public private(set) var xctestcaseSubclasses: Set<String> = []

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", allowed_prefixes: [\(allowedPrefixes)]" +
            ", xctestcase_subclasses: [\(xctestcaseSubclasses)]"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedPrefixes = configuration["allowed_prefixes"] as? [String] {
            self.allowedPrefixes = Set(allowedPrefixes)
        }

        if let xctestcaseSubclasses = configuration["xctestcase_subclasses"] as? [String] {
            self.xctestcaseSubclasses = Set(xctestcaseSubclasses)
        }
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }
}
