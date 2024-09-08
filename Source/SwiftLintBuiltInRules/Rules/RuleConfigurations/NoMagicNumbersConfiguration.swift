import SwiftLintCore

@AutoConfigParser
struct NoMagicNumbersConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = NoMagicNumbersRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "test_parent_classes",
        postprocessor: { $0.formUnion(["QuickSpec", "XCTestCase"]) }
    )
    private(set) var testParentClasses = Set<String>()
    @ConfigurationElement(
        key: "macros_to_ignore",
        postprocessor: { $0.formUnion(["Preview"]) }
    )
    private(set) var macrosToIgnore = Set<String>()
}
