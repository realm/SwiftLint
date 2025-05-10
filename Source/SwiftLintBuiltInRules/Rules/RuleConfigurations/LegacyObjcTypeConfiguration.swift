import SwiftLintCore

@AutoConfigParser
struct LegacyObjcTypeConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = LegacyObjcTypeRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "allowed_types")
    private(set) var allowedTypes: Set<String> = []
}
