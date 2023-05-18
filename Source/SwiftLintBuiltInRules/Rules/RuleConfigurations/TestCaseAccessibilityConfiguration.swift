struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TestCaseAccessibilityRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowedPrefixes: Set<String> = []
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", allowed_prefixes: \(allowedPrefixes.sorted())" +
            ", test_parent_classes: \(testParentClasses.sorted())"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
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
