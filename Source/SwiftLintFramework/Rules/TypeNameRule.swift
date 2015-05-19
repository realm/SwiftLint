//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

struct TypeNameRule: Rule {
    let identifier = "type_name"
    let parameters = [RuleParameter<Void>]()

    func validateFile(file: File) -> [StyleViolation] {
        return self.validateFile(file, dictionary: Structure(file: file).dictionary)
    }

    func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation] {
        return (dictionary["key.substructure"] as? XPCArray ?? []).flatMap { subItem in
            var violations = [StyleViolation]()
            if let subDict = subItem as? XPCDictionary,
                let kindString = subDict["key.kind"] as? String,
                let kind = flatMap(kindString, { SwiftDeclarationKind(rawValue: $0) }) {
                violations.extend(self.validateFile(file, dictionary: subDict))
                violations.extend(self.validateFile(file, kind: kind, dictionary: subDict))
            }
            return violations
        }
    }

    func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum,
            .Enumelement
        ]
        if !contains(typeKinds, kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let name = dictionary["key.name"] as? String,
            let offset = flatMap(dictionary["key.offset"] as? Int64, { Int($0) }) {
            let location = Location(file: file, offset: offset)
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .High,
                    reason: "Type name should only contain alphanumeric characters: '\(name)'"))
            } else if !name.substringToIndex(name.startIndex.successor()).isUppercase() {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .High,
                    reason: "Type name should start with an uppercase character: '\(name)'"))
            } else if count(name) < 3 || count(name) > 40 {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    severity: .Medium,
                    reason: "Type name should be between 3 and 40 characters in length: " +
                    "'\(name)'"))
            }
        }
        return violations
    }
}
