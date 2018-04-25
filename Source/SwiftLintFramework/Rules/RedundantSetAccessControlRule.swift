//
//  RedundantSetAccessControlRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 02/03/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RedundantSetAccessControlRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_set_access_control",
        name: "Redundant Set Access Control Rule",
        description: "Property setter access level shouldn't be explicit if " +
                     "it's the same as the variable access level.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            "private(set) public var foo: Int",
            "public let foo: Int",
            "public var foo: Int",
            "var foo: Int"
        ],
        triggeringExamples: [
            "↓private(set) private var foo: Int",
            "↓fileprivate(set) fileprivate var foo: Int",
            "↓internal(set) internal var foo: Int",
            "↓public(set) public var foo: Int",
            """
            open class Foo {
                ↓open(set) open var bar: Int
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.variableKinds.contains(kind),
            dictionary.setterAccessibility == dictionary.accessibility else {
                return []
        }

        let explicitSetACL = dictionary.swiftAttributes.first { dict in
            return dict.attribute?.hasPrefix("source.decl.attribute.setter_access") ?? false
        }

        guard let offset = explicitSetACL?.offset else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
