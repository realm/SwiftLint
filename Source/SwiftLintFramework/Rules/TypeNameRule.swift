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

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length.",
        nonTriggeringExamples: TypeNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeNameRuleExamples.triggeringExamples
    )

    private let typeKinds = SwiftDeclarationKind.typeKinds()

    public func validate(file: File) -> [StyleViolation] {
        return validateTypeAliasesAndAssociatedTypes(in: file) +
            validate(file: file, dictionary: file.structure.dictionary)
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard typeKinds.contains(kind),
            let name = dictionary.name,
            let offset = dictionary.offset else {
                return []
        }

        return validate(name: name, dictionary: dictionary, file: file, offset: offset)
    }

    private func validateTypeAliasesAndAssociatedTypes(in file: File) -> [StyleViolation] {
        let rangesAndTokens = file.rangesAndTokens(matching: "(typealias|associatedtype)\\s+.+?\\b")
        return rangesAndTokens.flatMap { arg -> [StyleViolation] in
            let (_, tokens) = arg
            guard tokens.count == 2,
                let keywordToken = tokens.first,
                let nameToken = tokens.last,
                SyntaxKind(rawValue: keywordToken.type) == .keyword,
                SyntaxKind(rawValue: nameToken.type) == .identifier else {
                    return []
            }

            let contents = file.contents.bridge()
            guard let name = contents.substringWithByteRange(start: nameToken.offset,
                                                             length: nameToken.length) else {
                return []
            }

            return validate(name: name, file: file, offset: nameToken.offset)
        }
    }

    private func validate(name: String, dictionary: [String: SourceKitRepresentable] = [:], file: File,
                          offset: Int) -> [StyleViolation] {
        guard !configuration.excluded.contains(name) else {
            return []
        }

        let name = name.nameStrippingLeadingUnderscoreIfPrivate(dictionary)
        let containsAllowedSymbol = configuration.allowedSymbols.contains(where: name.contains)
        if !containsAllowedSymbol && !CharacterSet.alphanumerics.isSuperset(ofCharactersIn: name) {
            return [StyleViolation(ruleDescription: type(of: self).description,
               severity: .error,
               location: Location(file: file, byteOffset: offset),
               reason: "Type name should only contain alphanumeric characters: '\(name)'")]
        } else if configuration.validatesStartWithLowercase &&
            !name.substring(to: name.index(after: name.startIndex)).isUppercase() {
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
