import SwiftLintCore

@AutoConfigParser
struct TodoConfiguration: SeverityBasedRuleConfiguration {
    @AcceptableByConfigurationElement
    enum TodoKeyword: String, CaseIterable {
        case todo = "TODO"
        case fixme = "FIXME"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only")
    private(set) var only = TodoKeyword.allCases
}
