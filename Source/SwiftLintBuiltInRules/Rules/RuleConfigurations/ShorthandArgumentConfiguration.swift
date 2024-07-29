import SwiftLintCore

@AutoConfigParser
struct ShorthandArgumentConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ShorthandArgumentRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_until_line_after_opening_brace")
    private(set) var allowUntilLineAfterOpeningBrace = 4
    @ConfigurationElement(key: "always_disallow_more_than_one")
    private(set) var alwaysDisallowMoreThanOne = false
    @ConfigurationElement(key: "always_disallow_member_access")
    private(set) var alwaysDisallowMemberAccess = false
}
