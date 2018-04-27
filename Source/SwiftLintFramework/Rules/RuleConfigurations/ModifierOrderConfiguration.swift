//
//  ModifierOrderConfiguration.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 06/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ModifierOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var preferedModifierOrder = [SwiftDeclarationAttributeKind.ModifierGroup]()

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", prefered_modifier_order: \(preferedModifierOrder)"
    }

    public init(preferedModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup] = []) {
        self.preferedModifierOrder = preferedModifierOrder
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let preferedModifierOrder = configuration["prefered_modifier_order"] as? [String] {
            self.preferedModifierOrder = try preferedModifierOrder.map {
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

    public static func == (lhs: ModifierOrderConfiguration,
                           rhs: ModifierOrderConfiguration) -> Bool {
        return lhs.preferedModifierOrder == rhs.preferedModifierOrder &&
               lhs.severityConfiguration == rhs.severityConfiguration
    }
}
