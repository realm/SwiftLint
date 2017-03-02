//
//  TypeInterfaceRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 28/02/2017.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TypeInterfaceRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_interface",
        name: "Type Interface",
        description: "Properties should have a type interface",
        nonTriggeringExamples: [
            "var myVar: Int? = 0",
            "let myVar: Int = 0"
        ],
        triggeringExamples: [
            "var myVar↓ = 0",
            "let myVar↓ = 0"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if the property have a type
        if dictionary.typeName != nil {
                return []
        }

        // Violation found!
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        ]
    }
}
