import SwiftLintCore

@AutoApply
struct TodoConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = TodoRule

    @MakeAcceptableByConfigurationElement
    enum TodoKeyword: String, CaseIterable {
        case todo = "TODO"
        case fixme = "FIXME"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only")
    private(set) var only = TodoKeyword.allCases
}
