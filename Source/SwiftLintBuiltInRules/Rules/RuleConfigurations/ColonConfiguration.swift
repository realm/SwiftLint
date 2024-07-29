import SwiftLintCore

@AutoConfigParser
struct ColonConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ColonRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "flexible_right_spacing")
    private(set) var flexibleRightSpacing = false
    @ConfigurationElement(key: "apply_to_dictionaries")
    private(set) var applyToDictionaries = true
}
