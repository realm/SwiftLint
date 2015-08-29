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
    public init() {}

    public static let description = RuleDescription(
        identifier: "variable_name",
        name: "Variable Name",
        description: "Variable name should only contain alphanumeric characters, " +
          "start with a a lowercase character and be between 3 and 40 characters in length. " +
          "In an exception to the above, variable names may start with a capital letter when " +
          "they are declared static and immutable.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0",
            "class Abc { static let MyLet = 0 }"
        ],
        triggeringExamples: [
            "let MyLet = 0",
            "let _myLet = 0",
            "private let myLet_ = 0",
            "let my = 0"
        ]
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
        let variableKinds: [SwiftDeclarationKind] = [
            .VarClass,
            .VarGlobal,
            .VarInstance,
            .VarLocal,
            .VarParameter,
            .VarStatic
        ]
        if !variableKinds.contains(kind) {
            return []
        }
        guard let name = dictionary["key.name"] as? String,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) else {
                return []
        }
        return name.violationsForNameAtLocation(Location(file: file, offset: offset),
            dictionary: dictionary, ruleDescription: self.dynamicType.description)
    }
}

extension String {
    private func violationsForNameAtLocation(location: Location, dictionary: XPCDictionary,
        ruleDescription: RuleDescription) -> [StyleViolation] {
        var violations = [StyleViolation]()
        if characters.first == "$" {
            // skip block variables
            return violations
        }
        if let kind = SwiftDeclarationKind(rawValue: (dictionary["key.kind"] as? String)!) {
          let name = nameStrippingLeadingUnderscoreIfPrivate(dictionary)
          let nameCharacterSet = NSCharacterSet(charactersInString: name)
          let firstCharacter = name.substringToIndex(name.startIndex.successor())
          if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
              violations.append(StyleViolation(ruleDescription: ruleDescription,
                  severity: .Error,
                  location: location,
                  reason: "Variable name should only contain alphanumeric characters: '\(name)'"))
          } else if kind != SwiftDeclarationKind.VarStatic && firstCharacter.isUppercase() {
              violations.append(StyleViolation(ruleDescription: ruleDescription,
                  severity: .Error,
                  location: location,
                  reason: "Variable name should start with a lowercase character: '\(name)'"))
          } else if name.characters.count < 3 || name.characters.count > 40 {
              violations.append(StyleViolation(ruleDescription: ruleDescription,
                  location: location,
                  reason: "Variable name should be between 3 and 40 characters in length: " +
                  "'\(name)'"))
          }
        }
        return violations
    }
}
