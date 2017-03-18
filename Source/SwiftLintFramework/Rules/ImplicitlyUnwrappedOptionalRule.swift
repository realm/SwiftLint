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
    public var configuration = ImplicitlyUnwrappedOptionalConfiguration(mode: .allExceptIBOutlets,
                                                                        severity: SeverityConfiguration(.warning))

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicitly_unwrapped_optional",
        name: "Implicitly Unwrapped Optional",
        description: "Implicitly unwrapped optionals should be avoided when possible.",
        nonTriggeringExamples: [
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "@IBOutlet var label: [UILabel!]",
            "if !boolean {}",
            "let int: Int? = 42",
            "let int: Int? = nil"
        ],
        triggeringExamples: [
            "let label: UILabel!",
            "let IBOutlet: UILabel!",
            "let labels: [UILabel!]",
            "var ints: [Int!] = [42, nil, 42]",
            "let label: IBOutlet!",
            "let int: Int! = 42",
            "let int: Int! = nil",
            "var int: Int! = 42",
            "let int: ImplicitlyUnwrappedOptional<Int>",
            "let collection: AnyCollection<Int!>",
            "func foo(int: Int!) {}"
        ]
    )

    private func hasImplicitlyUnwrappedOptional(_ typeName: String) -> Bool {
        return typeName.range(of: "!") != nil || typeName.range(of: "ImplicitlyUnwrappedOptional<") != nil
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.variableKinds().contains(kind) else {
            return []
        }

        guard let typeName = dictionary.typeName  else { return [] }
        guard hasImplicitlyUnwrappedOptional(typeName) else { return [] }

        if configuration.mode == .allExceptIBOutlets {
            let isOutlet = dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.iboutlet")
            if isOutlet { return [] }
        }

        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity.severity,
                           location: location)
        ]
    }

}
