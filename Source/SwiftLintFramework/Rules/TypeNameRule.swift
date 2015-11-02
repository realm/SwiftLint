//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct TypeNameRule: ASTRule, ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 3),
            RuleParameter(severity: .Warning, value: 40)
            ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let identifier = "type_name"

    public let parameters: [RuleParameter<Int>]

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
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum,
            .Enumelement
        ]
        if !typeKinds.contains(kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let name = dictionary["key.name"] as? String,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            let location = Location(file: file, offset: offset)
            let name = name.nameStrippingLeadingUnderscoreIfPrivate(dictionary)
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .Error,
                    reason: "Type name should only contain alphanumeric characters: '\(name)'"))
            } else if !name.substringToIndex(name.startIndex.successor()).isUppercase() {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .Error,
                    reason: "Type name should start with an uppercase character: '\(name)'"))
            } else if name.characters.count < parameters[0].value || name.characters.count > parameters[1].value {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .Warning,
                    reason: "Type name should be between \(parameters[0].value) and \(parameters[1].value) characters in length: " +
                    "'\(name)'"))
            }
        }
        return violations
    }

    public let example = RuleExample(
        ruleName: "Type Name Rule",
        ruleDescription: "Type name should only contain alphanumeric characters, " +
        "start with an uppercase character and have character length within specified range (default: 3-40).",
        nonTriggeringExamples: [
            "struct MyStruct {}",
            "private struct _MyStruct {}"
        ],
        triggeringExamples: [
            "struct myStruct {}",
            "struct _MyStruct {}",
            "private struct MyStruct_ {}",
            "struct My {}"
        ],
        showExamples: false
    )
}
