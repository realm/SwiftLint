//
//  VariableNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct VariableNameRule: ASTRule {
    public static let description = RuleDescription(
        identifier: "variable_name",
        name: "Variable Name",
        description: "Variable name should only contain alphanumeric characters and " +
          "start with a lowercase character or should only contain capital letters. " +
          "In an exception to the above, variable names may start with a capital letter " +
          "when they are declared static and immutable.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0",
            "class Abc { static let MyLet = 0 }",
            "let URL: NSURL? = nil"
        ],
        triggeringExamples: [
            "↓let MyLet = 0",
            "↓let _myLet = 0",
            "private ↓let myLet_ = 0"
        ]
    )

    private func nameIsViolatingCase(name: String) -> Bool {
        let firstCharacter = name.substringToIndex(name.startIndex.successor())
        return firstCharacter.isUppercase() && !name.isUppercase()
    }

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: XPCDictionary) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            let description = self.dynamicType.description
            let location = Location(file: file, byteOffset: offset)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                return [StyleViolation(ruleDescription: description,
                    severity: .Error,
                    location: location,
                    reason: "Variable name should only contain alphanumeric characters: '\(name)'")]
            } else if kind != SwiftDeclarationKind.VarStatic && nameIsViolatingCase(name) {
                return [StyleViolation(ruleDescription: description,
                    severity: .Error,
                    location: location,
                    reason: "Variable name should start with a lowercase character: '\(name)'")]
            }
            return []
        } ?? []
    }
}
