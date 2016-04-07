//
//  VariableNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
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
            "let XMLString: String? = nil"
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

    private func nameIsViolatingCase(name: String) -> Bool {
        let secondIndex = name.startIndex.successor()
        let firstCharacter = name.substringToIndex(secondIndex)
        if firstCharacter.isUppercase() {
            if name.characters.count > 1 {
                let range = secondIndex..<secondIndex.successor()
                let secondCharacter = name.substringWithRange(range)
                return secondCharacter.isLowercase()
            }
            return true
        }
        return false
    }

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            if configuration.excluded.contains(name) {
                return []
            }

            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            let description = self.dynamicType.description
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                return [StyleViolation(ruleDescription: description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should only contain alphanumeric " +
                            "characters: '\(name)'")]
            } else if kind != SwiftDeclarationKind.VarStatic && nameIsViolatingCase(name) {
                return [StyleViolation(ruleDescription: description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should start with a lowercase character: '\(name)'")]
            } else if let severity = severity(forLength: name.characters.count) {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should be between \(configuration.minLengthThreshold) " +
                            "and \(configuration.maxLengthThreshold) characters long: '\(name)'")]
            }

            return []
        } ?? []
    }
}
