import SourceKittenFramework
import SwiftLintCore

struct ModifierOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ModifierOrderRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "preferred_modifier_order")
    private(set) var preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup] = [
        .override,
        .acl,
        .setterACL,
        .dynamic,
        .mutators,
        .lazy,
        .final,
        .required,
        .convenience,
        .typeMethods,
        .owned
    ]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let preferredModifierOrder = configuration[$preferredModifierOrder] as? [String] {
            self.preferredModifierOrder = try preferredModifierOrder.map {
                guard let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawValue: $0),
                      modifierGroup != .atPrefixed else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }

                return modifierGroup
            }
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

extension SwiftDeclarationAttributeKind.ModifierGroup: AcceptableByConfigurationElement {
    public func asOption() -> OptionType { .symbol(rawValue) }
}
