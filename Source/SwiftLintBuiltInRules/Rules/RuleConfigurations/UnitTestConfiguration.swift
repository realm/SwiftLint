import SwiftLintCore

typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias FinalTestCaseConfiguration = UnitTestConfiguration<FinalTestCaseRule>
typealias NoMagicNumbersConfiguration = UnitTestConfiguration<NoMagicNumbersRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>

@AutoApply
struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) }
    )
    private(set) var testParentClasses = Set<String>()
}
