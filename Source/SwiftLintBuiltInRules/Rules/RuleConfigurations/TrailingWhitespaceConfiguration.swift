import SwiftLintCore

@AutoConfigParser
struct TrailingWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = TrailingWhitespaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignores_empty_lines")
    private(set) var ignoresEmptyLines = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = true
}
