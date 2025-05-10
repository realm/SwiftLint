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
        key: "allowed_numbers",
        postprocessor: { $0.formUnion([0, 1, 100]) }
    )
    private(set) var allowedNumbers = Set<Double>()
}
