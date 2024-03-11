import SwiftLintCore

@AutoApply
struct SwitchCaseOnNewLineConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = SwitchCaseOnNewlineRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "skip_switch_expressions")
    private(set) var skipSwitchExpressions = false
}
