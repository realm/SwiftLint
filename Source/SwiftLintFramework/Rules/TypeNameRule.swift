//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TypeNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 0,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length.",
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap({ type in
            [
                "\(type) MyType {}",
                "private \(type) _MyType {}",
                "enum MyType {\ncase value\n}",
                "\(type) " + repeatElement("A", count: 40).joined() + " {}"
            ]
        }),
        triggeringExamples: ["class", "struct", "enum"].flatMap({ type in
            [
                "↓\(type) myType {}",
                "↓\(type) _MyType {}",
                "private ↓\(type) MyType_ {}",
                "↓\(type) My {}",
                "↓\(type) " + repeatElement("A", count: 41).joined() + " {}"
            ]
        })
    )

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum
        ]
        if !typeKinds.contains(kind) {
            return []
        }
        if let name = dictionary["key.name"] as? String ,
            !configuration.excluded.contains(name),
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            let name = name.nameStrippingLeadingUnderscoreIfPrivate(dictionary)
            let nameCharacterSet = CharacterSet(charactersIn: name)
            if !CharacterSet.alphanumerics.isSuperset(of: nameCharacterSet) {
                return [StyleViolation(ruleDescription: type(of: self).description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should only contain alphanumeric characters: '\(name)'")]
            } else if !name.substring(to: name.index(after: name.startIndex)).isUppercase() {
                return [StyleViolation(ruleDescription: type(of: self).description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should start with an uppercase character: '\(name)'")]
            } else if let severity = severity(forLength: name.characters.count) {
                return [StyleViolation(ruleDescription: type(of: self).description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should be between \(configuration.minLengthThreshold) and " +
                        "\(configuration.maxLengthThreshold) characters long: '\(name)'")]
            }
        }
        return []
    }
}
