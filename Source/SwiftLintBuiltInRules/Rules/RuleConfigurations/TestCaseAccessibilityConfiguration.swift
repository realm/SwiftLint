import SwiftLintCore

@AutoApply
struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TestCaseAccessibilityRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_prefixes")
    private(set) var allowedPrefixes: Set<String> = []
    @ConfigurationElement(key: "test_parent_classes")
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]
}
