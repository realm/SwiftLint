@AutoApply
struct RedundantVoidReturnConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantVoidReturnRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_closures")
    private(set) var includeClosures = true
}
