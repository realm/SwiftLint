import SwiftLintCore

// swiftlint:disable:next type_name
struct NonOverridableClassDeclarationConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = NonOverridableClassDeclarationRule

    enum FinalClassModifier: String, AcceptableByConfigurationElement {
        case finalClass = "final class"
        case `static` = "static"

        func asOption() -> OptionType { .symbol(rawValue) }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "final_class_modifier")
    private(set) var finalClassModifier = FinalClassModifier.finalClass

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
        if let value = configuration[$finalClassModifier] as? String {
            if let modifier = FinalClassModifier(rawValue: value) {
                finalClassModifier = modifier
            } else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }
}
