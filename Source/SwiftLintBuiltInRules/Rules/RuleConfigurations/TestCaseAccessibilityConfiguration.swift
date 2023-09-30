import SwiftLintCore

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable let_var_whitespace

@AutoApply
struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TestCaseAccessibilityRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_prefixes")
    private(set) var allowedPrefixes: Set<String> = []
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) }
    )
    private(set) var testParentClasses = Set<String>()
}
