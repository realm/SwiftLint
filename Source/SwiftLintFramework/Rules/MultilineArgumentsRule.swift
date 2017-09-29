//
//  MultilineArgumentsRule.swift
//  SwiftLint
//
//  Created by Marcel Jackwerth on 29/09/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineArgumentsRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_arguments",
        name: "Multiline Arguments",
        description: "Arguments should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: MultilineArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineArgumentsRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1,
            case let contents = file.contents.bridge() else {
                return []
        }

        var visitedLines = Set<Int>()
        var hasCollisions = false

        let lastIndex = arguments.count - 1
        let violatingOffsets: [Int] = arguments.enumerated().flatMap { idx, argument in
            guard
                let offset = argument.offset,
                let (line, _) = contents.lineAndCharacter(forByteOffset: offset) else {
                    return nil
            }

            let (firstVisit, _) = visitedLines.insert(line)

            guard !firstVisit else {
                return nil
            }

            // never trigger on a trailing closure
            if idx == lastIndex, isTrailingClosure(dictionary: dictionary, file: file) {
                return nil
            }

            hasCollisions = hasCollisions || !firstVisit

            return offset
        }

        guard visitedLines.count > 1 && hasCollisions else {
            return []
        }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func isTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            case let start = min(offset, offset + length - 1),
            let text = file.contents.bridge().substringWithByteRange(start: start, length: length) else {
                return false
        }

        return !text.hasSuffix(")")
    }
}
