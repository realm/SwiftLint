import SwiftLintCore

@AutoConfigParser
struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OpeningBraceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_multiline_func")
    private(set) var allowMultilineFunc = false
    @ConfigurationElement(key: "ignore_multiline_type_headers")
    private(set) var ignoreMultilineTypeHeaders = false
}
