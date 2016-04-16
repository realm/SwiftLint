//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FunctionBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 40, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines."
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let functionKinds: [SwiftDeclarationKind] = [
            .FunctionAccessorAddress,
            .FunctionAccessorDidset,
            .FunctionAccessorGetter,
            .FunctionAccessorMutableaddress,
            .FunctionAccessorSetter,
            .FunctionAccessorWillset,
            .FunctionConstructor,
            .FunctionDestructor,
            .FunctionFree,
            .FunctionMethodClass,
            .FunctionMethodInstance,
            .FunctionMethodStatic,
            .FunctionOperator,
            .FunctionSubscript
        ]
        if !functionKinds.contains(kind) {
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
                            reason: "Function body should span \(parameter.value) lines or less " +
                            "excluding comments and whitespace: currently spans \(lineCount) " +
                            "lines")]
                    }

                }
            }
        }
        return []
    }
}
