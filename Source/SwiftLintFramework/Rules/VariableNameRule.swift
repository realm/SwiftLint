//
//  VariableNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VariableNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 2,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 60)

    public init() {}

    public static let description = RuleDescription(
        identifier: "variable_name",
        name: "Variable Name",
        description: "Variable names should only contain alphanumeric characters and " +
            "start with a lowercase character or should only contain capital letters. " +
            "In an exception to the above, variable names may start with a capital letter " +
            "when they are declared static and immutable. Variable names should not be too " +
            "long or too short.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0",
            "class Abc { static let MyLet = 0 }",
            "let URL: NSURL? = nil",
            "let XMLString: String? = nil",
            "override var i = 0"
        ],
        triggeringExamples: [
            "↓let MyLet = 0",
            "↓let _myLet = 0",
            "private ↓let myLet_ = 0",
            "↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0",
            "private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "↓let i = 0",
            "↓var id = 0",
            "private ↓let _i = 0"
        ]
    )

    fileprivate func nameIsViolatingCase(_ name: String) -> Bool {
        let secondIndex = name.characters.index(after: name.startIndex)
        let firstCharacter = name.substring(to: secondIndex)
        if firstCharacter.isUppercase() {
            if name.characters.count > 1 {
                let range = secondIndex..<name.characters.index(after: secondIndex)
                let secondCharacter = name.substring(with: range)
                return secondCharacter.isLowercase()
            }
            return true
        }
        return false
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard !dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.override") else {
            return []
        }

        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            if configuration.excluded.contains(name) {
                return []
            }

            let description = type(of: self).description
            if !CharacterSet.alphanumerics.isSuperset(ofCharactersIn: name) {
                return [StyleViolation(ruleDescription: description,
                    severity: .error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should only contain alphanumeric " +
                        "characters: '\(name)'")]
            } else if kind != SwiftDeclarationKind.varStatic && nameIsViolatingCase(name) {
                return [StyleViolation(ruleDescription: description,
                    severity: .error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should start with a lowercase character: '\(name)'")]
            } else if let severity = severity(forLength: name.characters.count) {
                return [StyleViolation(ruleDescription: type(of: self).description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should be between \(configuration.minLengthThreshold) " +
                        "and \(configuration.maxLengthThreshold) characters long: '\(name)'")]
            }

            return []
        } ?? []
    }
}
