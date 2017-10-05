//
//  OverrideInExtensionRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct OverrideInExtensionRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "override_in_extension",
        name: "Override in Extension",
        description: "Extensions shouldn't override declarations.",
        kind: .lint,
        nonTriggeringExamples: [
            "extension Person {\n  var age: Int { return 42 }\n}\n",
            "extension Person {\n  func celebrateBirthday() {}\n}\n",
            "class Employee: Person {\n  override func celebrateBirthday() {}\n}\n"
        ],
        triggeringExamples: [
            "extension Person {\n  override ↓var age: Int { return 42 }\n}\n",
            "extension Person {\n  override ↓func celebrateBirthday() {}\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .extension else {
            return []
        }

        let violatingOffsets = dictionary.substructure.flatMap { element -> Int? in
            guard element.kind.flatMap(SwiftDeclarationKind.init) != nil,
                element.enclosedSwiftAttributes.contains("source.decl.attribute.override"),
                let offset = element.offset else {
                    return nil
            }

            return offset
        }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }
}
