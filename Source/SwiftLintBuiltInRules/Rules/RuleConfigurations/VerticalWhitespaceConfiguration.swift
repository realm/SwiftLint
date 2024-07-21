import SwiftLintCore

@AutoConfigParser
struct VerticalWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = VerticalWhitespaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "max_empty_lines")
    private(set) var maxEmptyLines = 1
}
