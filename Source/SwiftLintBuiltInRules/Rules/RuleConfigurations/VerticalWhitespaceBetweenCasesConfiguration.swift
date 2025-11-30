import SwiftLintCore

@AutoConfigParser // swiftlint:disable:next type_name
struct VerticalWhitespaceBetweenCasesConfiguration: SeverityBasedRuleConfiguration {
    @AcceptableByConfigurationElement
    enum SeparationStyle: String {
        case always
        case never
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "separation")
    private(set) var separation: SeparationStyle = .always
}
