//
//  TypeBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

struct TypeBodyLengthRule: Rule {
    static let identifier = "type_body_length"
    static let parameters = [
        RuleParameter(severity: .VeryLow, value: 200),
        RuleParameter(severity: .Low, value: 250),
        RuleParameter(severity: .Medium, value: 300),
        RuleParameter(severity: .High, value: 350),
        RuleParameter(severity: .VeryHigh, value: 400)
    ]

    static func validateFile(file: File) -> [StyleViolation] {
        return self.validateFile(file, dictionary: Structure(file: file).dictionary)
    }

    static func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation] {
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

    static func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Enum
        ]
        if !contains(typeKinds, kind) {
            return []
        }
        if let offset = flatMap(dictionary["key.offset"] as? Int64, { Int($0) }),
            let bodyOffset = flatMap(dictionary["key.bodyoffset"] as? Int64, { Int($0) }),
            let bodyLength = flatMap(dictionary["key.bodylength"] as? Int64, { Int($0) }) {
            let location = Location(file: file, offset: offset)
            let startLine = file.contents.lineAndCharacterForByteOffset(bodyOffset)
            let endLine = file.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)
            for parameter in reverse(parameters) {
                if let startLine = startLine?.line, let endLine = endLine?.line
                    where endLine - startLine > parameter.value {
                    return [StyleViolation(type: .Length,
                        location: location,
                        severity: parameter.severity,
                        reason: "Type body should be span \(parameter.value) lines or less: currently spans " +
                        "\(endLine - startLine) lines")]
                }
            }
        }
        return []
    }
}
