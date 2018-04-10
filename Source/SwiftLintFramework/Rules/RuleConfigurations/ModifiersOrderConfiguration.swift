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

        if let beforeACL = configuration["prefered_modifiers_order"] as? [String] {
            self.preferedModifiersOrder = try beforeACL.map {
                guard let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawValue: $0) else {
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
