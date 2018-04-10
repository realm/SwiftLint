//
//  ModifiersOrderConfiguration.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 06/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ModifiersOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var preferedModifiersOrder = [SwiftDeclarationAttributeKind.ModifierGroup]()

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", prefered_modifiers_order: \(preferedModifiersOrder)"
    }

    public init(preferedModifiersOrder: [SwiftDeclarationAttributeKind.ModifierGroup] = []) {
        self.preferedModifiersOrder = preferedModifiersOrder
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let preferedModifiersOrder = configuration["prefered_modifiers_order"] as? [String] {
            self.preferedModifiersOrder = try preferedModifiersOrder.map {
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

    public static func == (lhs: ModifiersOrderConfiguration,
                           rhs: ModifiersOrderConfiguration) -> Bool {
        return lhs.preferedModifiersOrder == rhs.preferedModifiersOrder &&
               lhs.severityConfiguration == rhs.severityConfiguration
    }
}
