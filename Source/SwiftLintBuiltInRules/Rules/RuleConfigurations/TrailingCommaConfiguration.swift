import SwiftLintCore

@AutoApply
struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingCommaRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "mandatory_comma")
    private(set) var mandatoryComma = false
}
