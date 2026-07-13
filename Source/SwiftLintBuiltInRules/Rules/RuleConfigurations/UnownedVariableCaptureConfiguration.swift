import SwiftLintCore

@AutoConfigParser
struct UnownedVariableCaptureConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_unsafe")
    private(set) var includeUnsafe = false
}
