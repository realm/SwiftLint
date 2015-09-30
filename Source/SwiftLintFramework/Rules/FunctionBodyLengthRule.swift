//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct FunctionBodyLengthRule: ASTRule, ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 40),
            RuleParameter(severity: .Error, value: 100)
        ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let identifier = "function_body_length"

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
            let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) {
            let location = Location(file: file, offset: offset)
            let startLine = file.contents.lineAndCharacterForByteOffset(bodyOffset)
            let endLine = file.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)
            for parameter in parameters.reverse() {
                if let startLine = startLine?.line, let endLine = endLine?.line
                    where endLine - startLine > parameter.value {
                    return [StyleViolation(type: .Length,
                        location: location,
                        severity: parameter.severity,
                        reason: "Function body should be span \(parameters.first!.value) lines " +
                        "or less: currently spans \(endLine - startLine) lines")]
                }
            }
        }
        return []
    }

    public let example = RuleExample(
        ruleName: "Function Body Length Rule",
        ruleDescription: "This rule checks whether your function bodies are less than 40 lines.",
        nonTriggeringExamples: [],
        triggeringExamples: [],
        showExamples: false
    )
}
