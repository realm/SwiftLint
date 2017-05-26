//
//  IdentifierNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct IdentifierNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 2,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 60)

    public init() {}

    public static let description = RuleDescription(
        identifier: "identifier_name",
        name: "Identifier Name",
        description: "Identifier names should only contain alphanumeric characters and " +
            "start with a lowercase character or should only contain capital letters. " +
            "In an exception to the above, variable names may start with a capital letter " +
            "when they are declared static and immutable. Variable names should not be too " +
            "long or too short.",
        nonTriggeringExamples: IdentifierNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: IdentifierNameRuleExamples.triggeringExamples,
        deprecatedAliases: ["variable_name"]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard !dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.override") else {
            return []
        }

        return validateName(dictionary: dictionary, kind: kind).map { nameAndOffset in
            let (name, offset) = nameAndOffset
            guard !configuration.excluded.contains(name) else {
                return []
            }

            let isFunction = SwiftDeclarationKind.functionKinds().contains(kind)
            let description = Swift.type(of: self).description

            let type = self.type(for: kind)
            if !isFunction {
                let containsAllowedSymbol = configuration.allowedSymbols.contains(where: name.contains)
                if !containsAllowedSymbol &&
                    !CharacterSet.alphanumerics.isSuperset(ofCharactersIn: name) {
                    return [
                        StyleViolation(ruleDescription: description,
                                       severity: .error,
                                       location: Location(file: file, byteOffset: offset),
                                       reason: "\(type) name should only contain alphanumeric " +
                            "characters: '\(name)'")
                    ]
                }

                if let severity = severity(forLength: name.characters.count) {
                    let reason = "\(type) name should be between " +
                        "\(configuration.minLengthThreshold) and " +
                        "\(configuration.maxLengthThreshold) characters long: '\(name)'"
                    return [
                        StyleViolation(ruleDescription: Swift.type(of: self).description,
                                       severity: severity,
                                       location: Location(file: file, byteOffset: offset),
                                       reason: reason)
                    ]
                }
            }

            let requiresCaseCheck = configuration.validatesStartWithLowercase || isFunction
            if requiresCaseCheck &&
                kind != .varStatic && name.isViolatingCase && !name.isOperator {
                let reason = "\(type) name should start with a lowercase character: '\(name)'"
                return [
                    StyleViolation(ruleDescription: description,
                                   severity: .error,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: reason)
                ]
            }

            return []
        } ?? []
    }

    private func validateName(dictionary: [String: SourceKitRepresentable],
                              kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
        guard let name = dictionary.name,
            let offset = dictionary.offset,
            kinds.contains(kind),
            !name.hasPrefix("$") else {
                return nil
        }

        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }

    private let kinds: [SwiftDeclarationKind] = {
        return SwiftDeclarationKind.variableKinds() + SwiftDeclarationKind.functionKinds() + [.enumelement]
    }()

    private func type(for kind: SwiftDeclarationKind) -> String {
        if SwiftDeclarationKind.functionKinds().contains(kind) {
            return "Function"
        } else if kind == .enumelement {
            return "Enum element"
        } else {
            return "Variable"
        }
    }
}

fileprivate extension String {
    var isViolatingCase: Bool {
        let secondIndex = characters.index(after: startIndex)
        let firstCharacter = substring(to: secondIndex)
        guard firstCharacter.isUppercase() else {
            return false
        }
        guard characters.count > 1 else {
            return true
        }
        let range = secondIndex..<characters.index(after: secondIndex)
        let secondCharacter = substring(with: range)
        return secondCharacter.isLowercase()
    }

    var isOperator: Bool {
        let operators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&"]
        return !operators.filter(hasPrefix).isEmpty
    }
}
