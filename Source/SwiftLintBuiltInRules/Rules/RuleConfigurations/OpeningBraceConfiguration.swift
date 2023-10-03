import SwiftLintCore

@AutoApply
struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OpeningBraceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_multiline_func")
    private(set) var allowMultilineFunc = false
}
