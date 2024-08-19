import SwiftLintCore

@AutoConfigParser
struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = SwitchCaseAlignmentRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "indented_cases")
    private(set) var indentedCases = false
    @ConfigurationElement(key: "ignore_one_liners")
    private(set) var ignoreOneLiners = false
}
