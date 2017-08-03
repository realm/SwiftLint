//
//  ClosureBodyLengthRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/3/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ClosureBodyLengthRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 20, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            "foo.bar { $0 }",
            "foo.bar { value in\n" + repeatElement("\tprint(\"toto\")\n", count: 19).joined() + "\treturn value\n}",
            "foo.bar { value in\n\n" + repeatElement("\tprint(\"toto\")\n", count: 19).joined() + "\n\treturn value\n}"
        ],
        triggeringExamples: [
            "foo.bar {↓ value in\n" + repeatElement("\tprint(\"toto\")\n", count: 20).joined() + "\treturn value\n}",
            "foo.bar {↓ value in\n\n" + repeatElement("\tprint(\"toto\")\n", count: 20).joined() + "\n\treturn value\n}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let contents = file.contents.bridge(),
            contents.substringWithByteRange(start: bodyOffset - 1, length: 1) == "{",
            let startLine = contents.lineAndCharacter(forByteOffset: bodyOffset)?.line,
            let endLine = contents.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
            else {
                return []
        }

        return configuration.params.flatMap { parameter in
            let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(startLine,
                                                                                           endLine,
                                                                                           parameter.value)
            guard exceeds else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: parameter.severity,
                                  location: Location(file: file, byteOffset: bodyOffset),
                                  reason: "Closure body should span \(configuration.warning) lines or less " +
                                    "excluding comments and whitespace: currently spans \(lineCount) " + "lines")
        }
    }
}
