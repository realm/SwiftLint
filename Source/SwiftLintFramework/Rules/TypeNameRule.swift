//
//  TypeNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TypeNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NameConfig(minWarning: 3,
                                          minError: 0,
                                          maxWarning: 40,
                                          maxError: 1000)

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
            } else if let severity = violationSeverity(forLength: name.characters.count) {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Type name should be between \(configuration.minThreshold) and " +
                            "\(configuration.maxThreshold) characters long: '\(name)'")]
            }
        }
        return []
    }

    private func violationSeverity(forLength length: Int) -> ViolationSeverity? {
        if length < configuration.min.error.value ||
           length > configuration.max.error.value {
            return .Error
        } else if length < configuration.min.warning.value ||
                  length > configuration.max.warning.value {
            return .Warning
        } else {
            return nil
        }
    }
}
