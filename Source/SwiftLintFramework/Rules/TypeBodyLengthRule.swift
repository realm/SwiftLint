//
//  TypeBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

private func example(type: String, _ template: String, _ count: Int, _ add: String = "") -> String {
    return "\(type) Abc {\n" +
        Repeat(count: count, repeatedValue: template).joinWithSeparator("") + "\(add)}\n"
}

public struct TypeBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 200, error: 350)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_body_length",
        name: "Type Body Length",
        description: "Type bodies should not span too many lines.",
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap({ type in
            [
                example(type, "let abc = 0\n", 199),
                example(type, "\n", 201),
                example(type, "// this is a comment\n", 201),
                example(type, "let abc = 0\n", 199, "\n/* this is\na multiline comment\n*/\n")
            ]
        }),
        triggeringExamples: ["class", "struct", "enum"].map({ type in
            example(type, "let abc = 0\n", 201)
        })
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [.Class, .Struct, .Enum]
        if !typeKinds.contains(kind) {
            return []
        }
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) {
            let startLine = file.contents.lineAndCharacterForByteOffset(bodyOffset)
            let endLine = file.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)

            if let startLine = startLine?.line, endLine = endLine?.line {
                for parameter in configuration.params {
                    let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(
                                                                startLine, endLine, parameter.value)
                    if exceeds {
                        return [StyleViolation(ruleDescription: self.dynamicType.description,
                            severity: parameter.severity,
                            location: Location(file: file, byteOffset: offset),
                            reason: "Type body should span \(parameter.value) lines or less " +
                            "excluding comments and whitespace: currently spans \(lineCount) " +
                            "lines")]
                    }
                }
            }
        }
        return []
    }
}
