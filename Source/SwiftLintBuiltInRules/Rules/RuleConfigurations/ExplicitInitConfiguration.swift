@AutoApply
struct ExplicitInitConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ExplicitInitRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_bare_init")
    private(set) var includeBareInit = false
}
