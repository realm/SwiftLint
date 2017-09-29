//
//  MultilineArgumentsRule.swift
//  SwiftLint
//
//  Created by Marcel Jackwerth on 09/29/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineArgumentsRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = MultilineArgumentsConfiguration()

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
            case let contents = file.contents.bridge(),
            let nameOffset = dictionary.nameOffset,
            let (nameLine, _) = contents.lineAndCharacter(forByteOffset: nameOffset) else {
                return []
        }

        var visitedLines = Set<Int>()

        if configuration.firstArgumentLocation == .sameLine {
            visitedLines.insert(nameLine)
        }

        let lastIndex = arguments.count - 1
        let violatingOffsets: [Int] = arguments.enumerated().flatMap { idx, argument in
            guard
                let offset = argument.offset,
                let (line, _) = contents.lineAndCharacter(forByteOffset: offset) else {
                    return nil
            }

            let (firstVisit, _) = visitedLines.insert(line)

            if idx == lastIndex && isTrailingClosure(dictionary: dictionary, file: file) {
                return nil
            } else if idx == 0 {
                switch configuration.firstArgumentLocation {
                case .anyLine: return nil
                case .nextLine: return line > nameLine ? nil : offset
                case .sameLine: return line > nameLine ? offset : nil
                }
            } else {
                return firstVisit ? nil : offset
            }
        }

        // only report violations if multiline
        guard visitedLines.count > 1 else { return [] }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
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
