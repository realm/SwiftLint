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
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else { return [] }

        return findClosures(on: dictionary)
            .flatMap { closureDictionary -> (Int, Int, Int)? in
                guard
                    let bodyOffset = closureDictionary.bodyOffset,
                    let bodyLength = closureDictionary.bodyLength,
                    case let contents = file.contents.bridge(),
                    let startLine = contents.lineAndCharacter(forByteOffset: bodyOffset)?.line,
                    let endLine = contents.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
                    else { return nil }

                return (offset: bodyOffset, startLine: startLine, endLine: endLine)
            }
            .flatMap { offset, startLine, endLine -> [StyleViolation] in
                return configuration.params.flatMap { parameter -> StyleViolation? in
                    let (exceeds, count) = file.exceedsLineCountExcludingCommentsAndWhitespace(startLine,
                                                                                               endLine,
                                                                                               parameter.value)
                    guard exceeds else { return nil }

                    let reason = "Closure body should span \(configuration.warning) lines or less " +
                        "excluding comments and whitespace: currently spans \(count) " + "lines"

                    return StyleViolation(ruleDescription: type(of: self).description,
                                          severity: parameter.severity,
                                          location: Location(file: file, byteOffset: offset),
                                          reason: reason)
                }
            }
    }

    // MARK: - Private

    private func findClosures(on dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        let trailingClosures = dictionary.substructure
            .filter { $0.kind == StatementKind.brace.rawValue }

        let closuresAsArgument = dictionary.substructure
            .filter { $0.kind == SwiftExpressionKind.argument.rawValue }
            .flatMap { $0.substructure.filter { $0.kind == StatementKind.brace.rawValue } }

        return trailingClosures + closuresAsArgument
    }
}
