//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TypeNameRule: ASTRule {

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length.",
        nonTriggeringExamples: [
            "struct MyStruct {}",
            "private struct _MyStruct {}"
        ],
        triggeringExamples: [
            "↓struct myStruct {}",
            "↓struct _MyStruct {}",
            "private ↓struct MyStruct_ {}",
            "↓struct My {}"
        ]
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
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
        if let name = dictionary["key.name"] as? String,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            let name = name.nameStrippingLeadingUnderscoreIfPrivate(dictionary)
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should only contain alphanumeric characters: '\(name)'")]
            } else if !name.substringToIndex(name.startIndex.successor()).isUppercase() {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: .Error,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should start with an uppercase character: '\(name)'")]
            } else if name.characters.count < 3 || name.characters.count > 40 {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should be between 3 and 40 characters in length: '\(name)'")]
            }
        }
        return []
    }
}
