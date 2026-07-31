import SwiftLintCore

@AutoConfigParser
struct UnownedVariableCaptureConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_explicit_unsafe_unowned")
    private(set) var allowExplicitUnsafeUnowned = false
}
