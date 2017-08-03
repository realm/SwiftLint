//
//  ClosureBodyLengthRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/3/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func buildExample(codeLinesCount: Int, commentLinesCount: Int, emptyLinesCount: Int) -> String {
    return "foo.bar {\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
        repeatElement("\t// toto\n", count: commentLinesCount).joined() +
        repeatElement("\t\n", count: emptyLinesCount).joined() +
    "}"
}

public struct ClosureBodyLengthRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 20, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            buildExample(codeLinesCount: 1, commentLinesCount: 0, emptyLinesCount: 0),
            buildExample(codeLinesCount: 1, commentLinesCount: 99, emptyLinesCount: 99),
            buildExample(codeLinesCount: 1, commentLinesCount: 100, emptyLinesCount: 100),
            buildExample(codeLinesCount: 20, commentLinesCount: 0, emptyLinesCount: 0),
            buildExample(codeLinesCount: 20, commentLinesCount: 99, emptyLinesCount: 99),
            buildExample(codeLinesCount: 20, commentLinesCount: 100, emptyLinesCount: 100)
        ],
        triggeringExamples: [
            "↓" + buildExample(codeLinesCount: 21, commentLinesCount: 0, emptyLinesCount: 0),
            "↓" + buildExample(codeLinesCount: 50, commentLinesCount: 99, emptyLinesCount: 99),
            "↓" + buildExample(codeLinesCount: 99, commentLinesCount: 100, emptyLinesCount: 100),
            "↓" + buildExample(codeLinesCount: 100, commentLinesCount: 100, emptyLinesCount: 100)
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
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

            let reason = "Closure body should span \(configuration.warning) lines or less " +
                "excluding comments and whitespace: currently spans \(lineCount) " + "lines"

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: parameter.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }
}
