//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
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

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let functionKinds: [SwiftDeclarationKind] = [
            .functionAccessorAddress,
            .functionAccessorDidset,
            .functionAccessorGetter,
            .functionAccessorMutableaddress,
            .functionAccessorSetter,
            .functionAccessorWillset,
            .functionConstructor,
            .functionDestructor,
            .functionFree,
            .functionMethodClass,
            .functionMethodInstance,
            .functionMethodStatic,
            .functionOperator,
            .functionSubscript
        ]
        if !functionKinds.contains(kind) {
            return []
        }
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) {
            let startLine = file.contents.lineAndCharacter(forByteOffset: bodyOffset)
            let endLine = file.contents.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)

            if let startLine = startLine?.line, let endLine = endLine?.line {
                for parameter in configuration.params {
                    let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(
                        startLine, endLine, parameter.value
                    )
                    if exceeds {
                        return [StyleViolation(ruleDescription: type(of: self).description,
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
