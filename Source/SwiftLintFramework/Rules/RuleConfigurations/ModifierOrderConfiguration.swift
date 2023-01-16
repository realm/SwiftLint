import SourceKittenFramework

struct ModifierOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var preferredModifierOrder = [SwiftDeclarationAttributeKind.ModifierGroup]()

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)"
            + ", preferred_modifier_order: \(preferredModifierOrder)"
    }

    init() {
        self.preferredModifierOrder = []
    }

    init(preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup] = []) {
        self.preferredModifierOrder = preferredModifierOrder
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let preferredModifierOrder = configuration["preferred_modifier_order"] as? [String] {
            self.preferredModifierOrder = try preferredModifierOrder.map {
                guard let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawValue: $0),
                      modifierGroup != .atPrefixed else {
                    throw ConfigurationError.unknownConfiguration
                }

                return modifierGroup
            }
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
