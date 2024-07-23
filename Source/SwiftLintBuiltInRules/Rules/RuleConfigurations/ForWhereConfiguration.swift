import SwiftLintCore

@AutoConfigParser
struct ForWhereConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ForWhereRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_for_as_filter")
    private(set) var allowForAsFilter = false
}
