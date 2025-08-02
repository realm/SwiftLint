import SwiftLintCore

@AutoConfigParser
struct NonOptionalStringDataConversionConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name
    typealias Parent = NonOptionalStringDataConversionRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "include_variables")
    private(set) var includeVariables = false
}
