import SwiftLintCore

@AutoApply
struct SwitchCaseOnNewLineConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = SwitchCaseOnNewlineRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_returnless_cases")
    private(set) var allowReturnlessCases = false
}
