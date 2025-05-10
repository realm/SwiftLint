import SourceKittenFramework
import SwiftLintCore

@AutoConfigParser
struct ModifierOrderConfiguration: SeverityBasedRuleConfiguration {
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
        .owned,
    ]
}

extension SwiftDeclarationAttributeKind.ModifierGroup: AcceptableByConfigurationElement {
    public init(fromAny value: Any, context ruleID: String) throws {
        if let value = value as? String, let newSelf = Self(rawValue: value), newSelf != .atPrefixed {
            self = newSelf
        } else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
    }

    public func asOption() -> OptionType { .symbol(rawValue) }
}
