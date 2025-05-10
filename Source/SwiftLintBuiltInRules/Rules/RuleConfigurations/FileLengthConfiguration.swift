import SwiftLintCore

@AutoConfigParser
struct FileLengthConfiguration: RuleConfiguration {
    typealias Parent = FileLengthRule

    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 400, error: 1000)
    @ConfigurationElement(key: "ignore_comment_only_lines")
    private(set) var ignoreCommentOnlyLines = false
}
