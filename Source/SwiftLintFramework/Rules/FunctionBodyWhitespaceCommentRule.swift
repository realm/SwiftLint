//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 5/24/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FunctionBodyWhitespaceCommentRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 0, error: 0)

    public init() {}

    public static let description = RuleDescription(
            identifier: "function_body_whitespace_comment",
            name: "Function Body Empty Lines",
            description: "Functions bodies should not have whitespace and comment lines.",
            kind: .metrics
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
            let (exceeds, lineCount) = file.exceedsCommentAndWhitespaceLines(
                    startLine, endLine, parameter.value
            )
            guard exceeds else { continue }
            return [StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: parameter.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Function body should span \(configuration.warning) comment and whitespace lines or less " +
                            ": currently spans \(lineCount) " +
                            "lines")]
        }
        return []
    }
}
