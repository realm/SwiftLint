import SwiftLintCore

@AutoConfigParser
struct OptionalDataStringConversionConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_shorthand_init")
    private(set) var includeShorthandInit = false
}
