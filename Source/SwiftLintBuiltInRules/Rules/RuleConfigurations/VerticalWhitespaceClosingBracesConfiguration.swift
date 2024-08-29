import SwiftLintCore

@AutoConfigParser // swiftlint:disable:next type_name
struct VerticalWhitespaceClosingBracesConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = VerticalWhitespaceClosingBracesRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_enforce_before_trivial_lines")
    private(set) var onlyEnforceBeforeTrivialLines = false
}
