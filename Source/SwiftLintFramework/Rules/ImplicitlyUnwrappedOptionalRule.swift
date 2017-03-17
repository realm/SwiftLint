//
//  ImplicitlyUnwrappedOptionalRule.swift
//  SwiftLint
//
//  Created by Siarhei Fedartsou on 17/03/17.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ImplicitlyUnwrappedOptionalRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicitly_unwrapped_optional",
        name: "Implicitly Unwrapped Optional",
        description: "Implicitly unwrapped optionals should be avoided when possible.",
        nonTriggeringExamples: [
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "if !boolean {}",
            "let int: Int? = 42",
            "let int: Int? = nil"
        ],
        triggeringExamples: [
            "let label: UILabel!",
            "let IBOutlet: UILabel!",
            "let label: IBOutlet!",
            "let int: Int! = 42",
            "let int: Int! = nil",
            "var int: Int! = 42"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.variableKinds().contains(kind) else {
            return []
        }

        guard let typeName = dictionary.typeName  else { return [] }
        guard typeName.hasSuffix("!") else { return [] }

        let isOutlet = dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.iboutlet")
        if isOutlet { return [] }

        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: location)
        ]
    }

}
