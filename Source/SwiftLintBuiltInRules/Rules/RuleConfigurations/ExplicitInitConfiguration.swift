@AutoConfigParser
struct ExplicitInitConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_bare_init")
    private(set) var includeBareInit = false
}
