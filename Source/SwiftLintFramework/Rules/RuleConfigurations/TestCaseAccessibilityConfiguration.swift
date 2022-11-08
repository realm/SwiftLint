struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var allowedPrefixes: Set<String> = []
    private(set) var testParentClasses: Set<String> = ["XCTestCase"]

    var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", allowed_prefixes: [\(allowedPrefixes)]" +
            ", test_parent_classes: [\(testParentClasses)]"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedPrefixes = configuration["allowed_prefixes"] as? [String] {
            self.allowedPrefixes = Set(allowedPrefixes)
        }

        if let extraTestParentClasses = configuration["test_parent_classes"] as? [String] {
            self.testParentClasses.formUnion(extraTestParentClasses)
        }
    }
}
