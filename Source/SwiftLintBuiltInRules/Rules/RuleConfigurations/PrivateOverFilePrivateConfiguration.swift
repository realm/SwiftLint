import SwiftLintCore

@AutoApply
struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrivateOverFilePrivateRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_extensions")
    var validateExtensions = false
}
