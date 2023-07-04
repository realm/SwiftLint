import SwiftLintCore

typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>
typealias NoMagicNumbersConfiguration = UnitTestConfiguration<NoMagicNumbersRule>

struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "test_parent_classes")
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let extraTestParentClasses = configuration[$testParentClasses] as? [String] {
            self.testParentClasses.formUnion(extraTestParentClasses)
        }
    }
}
