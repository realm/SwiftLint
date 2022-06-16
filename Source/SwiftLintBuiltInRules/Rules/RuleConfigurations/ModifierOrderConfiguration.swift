import SourceKittenFramework

struct ModifierOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ModifierOrderRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
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

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "preferred_modifier_order" => .list(preferredModifierOrder.map { .symbol($0.rawValue) })
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let preferredModifierOrder = configuration["preferred_modifier_order"] as? [String] {
            self.preferredModifierOrder = try preferredModifierOrder.map {
                guard let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawValue: $0),
                      modifierGroup != .atPrefixed else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }

                return modifierGroup
            }
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
