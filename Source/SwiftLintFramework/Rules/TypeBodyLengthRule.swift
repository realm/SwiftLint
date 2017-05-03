//
//  TypeBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

private func example(_ type: String,
                     _ template: String,
                     _ count: Int,
                     _ add: String = "") -> String {
    return "\(type) Abc {\n" +
        repeatElement(template, count: count).joined() + "\(add)}\n"
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
            "↓" + example(type, "let abc = 0\n", 201)
        })
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.typeKinds().contains(kind) else {
            return []
        }
        if let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength {
            let startLine = file.contents.bridge().lineAndCharacter(forByteOffset: bodyOffset)
            let endLine = file.contents.bridge()
                .lineAndCharacter(forByteOffset: bodyOffset + bodyLength)

            if let startLine = startLine?.line, let endLine = endLine?.line {
                for parameter in configuration.params {
                    let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(
                        startLine, endLine, parameter.value
                    )
                    if exceeds {
                        return [StyleViolation(ruleDescription: type(of: self).description,
                            severity: parameter.severity,
                            location: Location(file: file, byteOffset: offset),
                            reason: "Type body should span \(configuration.warning) lines or less " +
                                "excluding comments and whitespace: currently spans \(lineCount) " +
                                "lines")]
                    }
                }
            }
        }
        return []
    }
}
