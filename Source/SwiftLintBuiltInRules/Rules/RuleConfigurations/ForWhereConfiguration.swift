import SwiftLintCore

@AutoApply
struct ForWhereConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ForWhereRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_for_as_filter")
    private(set) var allowForAsFilter = false
}
