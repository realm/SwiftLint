//
//  VariableNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VariableNameRule: ASTRule, ConfigProviderRule {

    public var config = NameConfig(minLengthWarning: 3,
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
            Trigger("let myLet = 0"),
            Trigger("var myVar = 0"),
            Trigger("private let _myLet = 0"),
            Trigger("class Abc { static let MyLet = 0 }"),
            Trigger("let URL: NSURL? = nil")
        ],
        triggeringExamples: [
            Trigger("↓let MyLet = 0"),
            Trigger("↓let _myLet = 0"),
            Trigger("private ↓let myLet_ = 0"),
            Trigger("↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
            Trigger("↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0"),
            Trigger("private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
            Trigger("↓let i = 0"),
            Trigger("↓var id = 0"),
            Trigger("private ↓let _i = 0")
        ]
    )

    private func nameIsViolatingCase(name: String) -> Bool {
        let firstCharacter = name.substringToIndex(name.startIndex.successor())
        return firstCharacter.isUppercase() && !name.isUppercase()
    }

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            if config.excluded.contains(name) {
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
                    reason: "Variable name should be between \(config.minLengthThreshold) " +
                            "and \(config.maxLengthThreshold) characters long: '\(name)'")]
            }

            return []
        } ?? []
    }
}
