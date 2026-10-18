import SwiftLintCore

@AutoConfigParser
struct ValidIBInspectableConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    /// Exact type spellings for supported typealiases. Optional and implicitly
    /// unwrapped spellings must be configured separately.
    @ConfigurationElement(key: "additional_types")
    private(set) var additionalTypes = Set<String>()
}
