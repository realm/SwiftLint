//
//  VerticalParameterAlignmentOnCallRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 02/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VerticalParameterAlignmentOnCallRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "vertical_parameter_alignment_on_call",
        name: "Vertical Parameter Alignment On Call",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a method call.",
        nonTriggeringExamples: [
            "foo(param1: 1, param2: bar\n" +
            "    param3: false, param4: true)",
            "foo(param1: 1, param2: bar)",
            "foo(param1: 1, param2: bar\n" +
            "    param3: false,\n" +
            "    param4: true)",
            "foo(\n" +
            "   param1: 1\n" +
            ") { _ in }"
        ],
        triggeringExamples: [
            "foo(param1: 1, param2: bar\n" +
            "                ↓param3: false, param4: true)",
            "foo(param1: 1, param2: bar\n" +
            " ↓param3: false, param4: true)",
            "foo(param1: 1, param2: bar\n" +
            "       ↓param3: false,\n" +
            "       ↓param4: true)",
            "foo(param1: 1,\n" +
            "       ↓param2: { _ in })"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1,
            let firstArgumentOffset = arguments.first?.offset,
            case let contents = file.contents.bridge(),
            let firstArgumentPosition = contents.lineAndCharacter(forByteOffset: firstArgumentOffset) else {
                return []
        }

        var visitedLines: Set<Int> = []
        let violatingOffsets: [Int] = arguments.dropFirst().flatMap { argument in
            guard let offset = argument.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: offset),
                line > firstArgumentPosition.line else {
                    return nil
            }

            let (firstVisit, _) = visitedLines.insert(line)
            guard character != firstArgumentPosition.character && firstVisit else {
                return nil
            }

            if argument.bridge() == arguments.last?.bridge(),
                isClosure(argument, file: file),
                isAlreadyTrailingClosure(dictionary: dictionary, file: file) {
                return nil
            }

            return offset
        }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func isClosure(_ argument: [String: SourceKitRepresentable],
                           file: File) -> Bool {
        guard let offset = argument.bodyOffset,
            let length = argument.bodyLength,
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
            let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location else {
                return false
        }

        return true
    }

    private func isAlreadyTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let text = file.contents.bridge().substringWithByteRange(start: offset, length: length) else {
                return false
        }

        return !text.hasSuffix(")")
    }

}
