import SwiftLintCore

typealias BalancedXCTestLifecycleConfiguration = UnitTestConfiguration<BalancedXCTestLifecycleRule>
typealias EmptyXCTestMethodConfiguration = UnitTestConfiguration<EmptyXCTestMethodRule>
typealias SingleTestClassConfiguration = UnitTestConfiguration<SingleTestClassRule>
typealias NoMagicNumbersConfiguration = UnitTestConfiguration<NoMagicNumbersRule>

@AutoApply
struct UnitTestConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "test_parent_classes")
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]
}
