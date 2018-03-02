//
//  FunctionBodyCommentsRule.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 02/28/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FunctionBodyCommentsRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityLevelsConfiguration(warning: 0, error: 0)

    public init() {}

    public static let description = RuleDescription(
            identifier: "function_body_comments",
            name: "Function Body Comments",
            description: "Functions bodies should not have comments.",
            kind: .style
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
              let offset = dictionary.offset,
              let bodyOffset = dictionary.bodyOffset,
              let bodyLength = dictionary.bodyLength,
              case let contentsNSString = file.contents.bridge(),
              let startLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset)?.line,
              let endLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
                else {
            return []
        }
        for parameter in configuration.params {
            let (exceeds, lineCount) = file.exceedsCommentLines(
                    startLine, endLine, parameter.value
            )
            guard exceeds else { continue }
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: parameter.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Function body should span \(configuration.warning) lines or less " +
                        "of comments: currently spans \(lineCount) " +
                        "lines"
                )
            ]
        }
        return []
    }
}
