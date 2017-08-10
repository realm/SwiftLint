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
        kind: .style,
        nonTriggeringExamples: [
            "foo(param1: 1, param2: bar\n" +
            "    param3: false, param4: true)",
            "foo(param1: 1, param2: bar)",
            "foo(param1: 1, param2: bar\n" +
            "    param3: false,\n" +
            "    param4: true)",
            "foo(\n" +
            "   param1: 1\n" +
            ") { _ in }",
            "UIView.animate(withDuration: 0.4, animations: {\n" +
            "    blurredImageView.alpha = 1\n" +
            "}, completion: { _ in\n" +
            "    self.hideLoading()\n" +
            "})",
            "UIView.animate(withDuration: 0.4, animations: {\n" +
            "    blurredImageView.alpha = 1\n" +
            "},\n" +
            "completion: { _ in\n" +
            "    self.hideLoading()\n" +
            "})",
            "foo(param1: 1, param2: { _ in },\n" +
            "    param3: false, param4: true)",
            "foo({ _ in\n" +
            "       bar()\n" +
            "   },\n" +
            "   completion: { _ in\n" +
            "       baz()\n" +
            "   }\n" +
            ")",
            "foo(param1: 1, param2: [\n" +
            "   0,\n" +
            "   1\n" +
            "], param3: 0)"
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
            "       ↓param2: { _ in })",
            "foo(param1: 1,\n" +
            "    param2: { _ in\n" +
            "}, param3: 2,\n" +
            " ↓param4: 0)",
            "foo(param1: 1, param2: { _ in },\n" +
            "       ↓param3: false, param4: true)"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1,
            let firstArgumentOffset = arguments.first?.offset,
            case let contents = file.contents.bridge(),
            var firstArgumentPosition = contents.lineAndCharacter(forByteOffset: firstArgumentOffset) else {
                return []
        }

        var visitedLines = Set<Int>()
        var previousArgumentWasMultiline = false

        let lastIndex = arguments.count - 1
        let violatingOffsets: [Int] = arguments.enumerated().flatMap { idx, argument in
            defer {
                previousArgumentWasMultiline = isMultiline(argument: argument, file: file)
            }

            guard let offset = argument.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: offset),
                line > firstArgumentPosition.line else {
                    return nil
            }

            let (firstVisit, _) = visitedLines.insert(line)
            guard character != firstArgumentPosition.character && firstVisit else {
                return nil
            }

            // if this is the first element on a new line after a closure with multiple lines,
            // we reset the reference position
            if previousArgumentWasMultiline && firstVisit {
                firstArgumentPosition = (line, character)
                return nil
            }

            // never trigger on a trailing closure
            if idx == lastIndex, isTrailingClosure(dictionary: dictionary, file: file) {
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

    private func isMultiline(argument: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = argument.bodyOffset,
            let length = argument.bodyLength,
            case let contents = file.contents.bridge(),
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: offset),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: offset + length) else {
                return false
        }

        return endLine > startLine
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
