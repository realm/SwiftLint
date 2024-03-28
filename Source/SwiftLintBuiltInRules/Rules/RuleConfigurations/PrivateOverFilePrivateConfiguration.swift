import SwiftLintCore

@AutoApply
struct PrivateOverFilePrivateConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = PrivateOverFilePrivateRule

    @ConfigurationElement(key: "severity")
    var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "validate_extensions")
    var validateExtensions = false
}
