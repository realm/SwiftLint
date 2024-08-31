import SwiftLintCore

typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias FinalTestCaseConfiguration = UnitTestConfiguration<FinalTestCaseRule>
// NoMagicNumbersConfiguration should be kept in sync with UnitTestConfiguration
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>

@AutoConfigParser
struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) }
    )
    private(set) var testParentClasses = Set<String>()
}
