struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TestCaseAccessibilityRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowedPrefixes: Set<String> = []
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "allowed_prefixes" => .list(allowedPrefixes.sorted().map { .string($0) })
        "test_parent_classes" => .list(testParentClasses.sorted().map { .symbol($0) })
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
