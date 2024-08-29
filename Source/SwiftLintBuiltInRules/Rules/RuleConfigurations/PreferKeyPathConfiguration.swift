import SwiftLintCore

@AutoConfigParser
struct PreferKeyPathConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = PreferKeyPathRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "restrict_to_standard_functions")
    private(set) var restrictToStandardFunctions = true
}
