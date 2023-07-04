import SwiftLintCore

struct TestCaseAccessibilityConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TestCaseAccessibilityRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_prefixes")
    private(set) var allowedPrefixes: Set<String> = []
    @ConfigurationElement(key: "test_parent_classes")
    private(set) var testParentClasses: Set<String> = ["QuickSpec", "XCTestCase"]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedPrefixes = configuration[$allowedPrefixes] as? [String] {
            self.allowedPrefixes = Set(allowedPrefixes)
        }

        if let extraTestParentClasses = configuration[$testParentClasses] as? [String] {
            self.testParentClasses.formUnion(extraTestParentClasses)
        }
    }
}
