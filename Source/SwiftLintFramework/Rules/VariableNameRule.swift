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
        "start with a a lowercase character and be between 3 and 40 characters in length.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0"
        ],
        triggeringExamples: [
            "let MyLet = 0",
            "let _myLet = 0",
            "private let myLet_ = 0",
            "let my = 0"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation] {
        let substructure = dictionary["key.substructure"] as? XPCArray ?? []
        return substructure.flatMap { subItem -> [StyleViolation] in
            var violations = [StyleViolation]()
            if let subDict = subItem as? XPCDictionary,
                let kindString = subDict["key.kind"] as? String,
                let kind = SwiftDeclarationKind(rawValue: kindString) {
                violations.appendContentsOf(
                    self.validateFile(file, dictionary: subDict) +
                    self.validateFile(file, kind: kind, dictionary: subDict)
                )
            }
            return violations
        }
    }

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
        let name = nameStrippingLeadingUnderscoreIfPrivate(dictionary)
        let nameCharacterSet = NSCharacterSet(charactersInString: name)
        if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
            violations.append(StyleViolation(ruleDescription: ruleDescription,
                severity: .Error,
                location: location,
                reason: "Variable name should only contain alphanumeric characters: '\(name)'"))
        } else if name.substringToIndex(name.startIndex.successor()).isUppercase() {
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
        return violations
    }
}
