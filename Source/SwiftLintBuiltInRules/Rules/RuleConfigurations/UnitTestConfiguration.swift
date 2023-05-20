typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>
typealias NoMagicNumbersConfiguration = UnitTestConfiguration<NoMagicNumbersRule>

struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", test_parent_classes: \(testParentClasses.sorted())"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let extraTestParentClasses = configuration["test_parent_classes"] as? [String] {
            self.testParentClasses.formUnion(extraTestParentClasses)
        }
    }

    var severity: ViolationSeverity {
        return severityConfiguration.severity
    }
}
