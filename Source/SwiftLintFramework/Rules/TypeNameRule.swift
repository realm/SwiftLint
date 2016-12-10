//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TypeNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 0,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 1000)

    public init() {}

    private static func nonTriggeringExamples() -> [String] {
        let typeExamples: [String] = ["class", "struct", "enum"].flatMap { type -> [String] in
            [
                "\(type) MyType {}",
                "private \(type) _MyType {}",
                "enum MyType {\ncase value\n}",
                "\(type) \(repeatElement("A", count: 40).joined()) {}"
            ]
        }
        let typeAliasExamples = [
            "typealias Foo = Void",
            "private typealias Foo = Void"
        ]

        return typeExamples + typeAliasExamples
    }

    private static func triggeringExamples() -> [String] {
        let types = ["class", "struct", "enum"]
        let typeExamples: [String] = types.flatMap { (type: String) -> [String] in
            [
                "↓\(type) myType {}",
                "↓\(type) _MyType {}",
                "private ↓\(type) MyType_ {}",
                "↓\(type) My {}",
                "↓\(type) \(repeatElement("A", count: 41).joined()) {}"
            ]
        }
        let typeAliasExamples: [String] = [
            "typealias X = Void",
            "private typealias Foo_Bar = Void",
            "private typealias foo = Void",
            "typealias \(repeatElement("A", count: 41).joined()) = Void"
        ]

        return typeExamples + typeAliasExamples
    }

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length.",
        nonTriggeringExamples: TypeNameRule.nonTriggeringExamples(),
        triggeringExamples: TypeNameRule.triggeringExamples()
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        return validateTypeAliases(file) +
            validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .class,
            .struct,
            .typealias,
            .enum
        ]

        guard typeKinds.contains(kind),
            let name = dictionary["key.name"] as? String,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) else {
                return []
        }

        return validateName(name: name, dictionary: dictionary, file: file, offset: offset)
    }

    private func validateTypeAliases(_ file: File) -> [StyleViolation] {
        let rangesAndTokens = file.rangesAndTokensMatching("typealias\\s+.+?\\b")
        return rangesAndTokens.flatMap { range, tokens -> [StyleViolation] in
            guard tokens.count == 2,
                let keywordToken = tokens.first,
                let nameToken = tokens.last,
                SyntaxKind(rawValue: keywordToken.type) == .keyword,
                SyntaxKind(rawValue: nameToken.type) == .identifier else {
                    return []
            }

            guard let name = file.contents.substringWithByteRange(start: nameToken.offset,
                                                                  length: nameToken.length) else {
                return []
            }

            return validateName(name: name, file: file, offset: nameToken.offset)
        }
    }

    private func validateName(name: String,
                              dictionary: [String: SourceKitRepresentable] = [:],
                              file: File,
                              offset: Int) -> [StyleViolation] {
        guard !configuration.excluded.contains(name) else {
            return []
        }

        let name = name.nameStrippingLeadingUnderscoreIfPrivate(dictionary)
        let nameCharacterSet = CharacterSet(charactersIn: name)
        if !CharacterSet.alphanumerics.isSuperset(of: nameCharacterSet) {
            return [StyleViolation(ruleDescription: type(of: self).description,
               severity: .error,
               location: Location(file: file, byteOffset: offset),
               reason: "Type name should only contain alphanumeric characters: '\(name)'")]
        } else if !name.substring(to: name.index(after: name.startIndex)).isUppercase() {
            return [StyleViolation(ruleDescription: type(of: self).description,
               severity: .error,
               location: Location(file: file, byteOffset: offset),
               reason: "Type name should start with an uppercase character: '\(name)'")]
        } else if let severity = severity(forLength: name.characters.count) {
            return [StyleViolation(ruleDescription: type(of: self).description,
               severity: severity,
               location: Location(file: file, byteOffset: offset),
               reason: "Type name should be between \(configuration.minLengthThreshold) and " +
                    "\(configuration.maxLengthThreshold) characters long: '\(name)'")]
        }

        return []
    }
}
