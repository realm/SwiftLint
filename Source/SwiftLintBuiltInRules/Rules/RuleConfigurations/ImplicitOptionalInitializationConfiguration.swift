import SwiftLintCore

@AutoConfigParser
struct ImplicitOptionalInitializationConfiguration: SeverityBasedRuleConfiguration { // swiftlint:disable:this type_name
    @AcceptableByConfigurationElement
    enum Style: String {
        case always
        case never
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "style")
    private(set) var style: Style = .always
}
