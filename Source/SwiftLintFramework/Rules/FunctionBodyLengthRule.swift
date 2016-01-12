//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct FunctionBodyLengthRule: ASTRule, ViolationLevelRule {
    public var warning = RuleParameter(severity: .Warning, value: 40)
    public var error = RuleParameter(severity: .Error, value: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines."
    )

    private func numberOfCommentOnlyLines(file: File, startLine: Int, endLine: Int) -> Int {
        let commentKinds = Set(SyntaxKind.commentKinds())

        return file.syntaxKindsByLines.filter { line, kinds -> Bool in
            // skip blank lines
            guard !kinds.isEmpty else {
                return false
            }

            guard line >= startLine && line <= endLine else {
                return false
            }

            return kinds.filter { !commentKinds.contains($0) }.isEmpty
        }.count
    }

    private func lineCount(file: File, startLine: Int, endLine: Int) -> Int {
        let commentedLines = numberOfCommentOnlyLines(file, startLine: startLine, endLine: endLine)
        return endLine - startLine - commentedLines
    }

    private func exceedsLineCountExcludingComments(file: File, _ start: Int, _ end: Int,
                                                   _ limit: Int) -> Bool {
        return end - start > limit && lineCount(file, startLine: start, endLine: end) > limit
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
            let location = Location(file: file, byteOffset: offset)
            let startLine = file.contents.lineAndCharacterForByteOffset(bodyOffset)
            let endLine = file.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)

            if let startLine = startLine?.line, let endLine = endLine?.line {
                for parameter in [error, warning]
                    where exceedsLineCountExcludingComments(file, startLine, endLine,
                                                            parameter.value) {
                        return [StyleViolation(ruleDescription: self.dynamicType.description,
                            severity: parameter.severity,
                            location: location,
                            reason: "Function body should span \(warning.value) lines " +
                            "or less: currently spans \(endLine - startLine) lines")]
                }
            }
        }
        return []
    }
}
