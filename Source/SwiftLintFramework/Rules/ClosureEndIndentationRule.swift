//
//  ClosureEndIndentationRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ClosureEndIndentationRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: [
            "SignalProducer(values: [1, 2, 3])\n" +
            "   .startWithNext { number in\n" +
            "       print(number)\n" +
            "   }\n",
            "[1, 2].map { $0 + 1 }\n",
            "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
            "   return Command(string: contents, range: range)\n" +
            "}.flatMap { command in\n" +
            "   return command.expand()\n" +
            "}\n",
            "foo(foo: bar,\n" +
            "    options: baz) { _ in }\n",
            "someReallyLongProperty.chainingWithAnotherProperty\n" +
            "   .foo { _ in }",
            "foo(abc, 123)\n" +
            "{ _ in }\n"
        ],
        triggeringExamples: [
            "SignalProducer(values: [1, 2, 3])\n" +
            "   .startWithNext { number in\n" +
            "       print(number)\n" +
            "↓}\n",
            "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
            "   return Command(string: contents, range: range)\n" +
            "   ↓}.flatMap { command in\n" +
            "   return command.expand()\n" +
            "↓}\n"
        ]
    )

    private static let notWhitespace = regex("[^\\s]")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else {
            return []
        }

        let contents = file.contents.bridge()
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            contents.substringWithByteRange(start: endOffset, length: 1) == "}",
            let startOffset = startOffset(forDictionary: dictionary, file: file),
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: startOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            case let nameEndPosition = nameOffset + nameLength,
            let (bodyOffsetLine, _) = contents.lineAndCharacter(forByteOffset: nameEndPosition),
            startLine != endLine, bodyOffsetLine != endLine,
            !containsSingleLineClosure(dictionary: dictionary, endPosition: endOffset, file: file) else {
                return []
        }

        let range = file.lines[startLine - 1].range
        let regex = ClosureEndIndentationRule.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual  else {
                return []
        }

        let reason = "Closure end should have the same indentation as the line that started it. " +
                     "Expected \(expected), got \(actual)."
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: endOffset),
                           reason: reason)
        ]
    }

    private func startOffset(forDictionary dictionary: [String: SourceKitRepresentable], file: File) -> Int? {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength else {
            return nil
        }

        let newLineRegex = regex("\n(\\s*\\}?\\.)")
        let contents = file.contents.bridge()
        guard let range = contents.byteRangeToNSRange(start: nameOffset, length: nameLength),
            let match = newLineRegex.matches(in: file.contents, options: [],
                                             range: range).last?.range(at: 1),
            let methodByteRange = contents.NSRangeToByteRange(start: match.location,
                                                              length: match.length) else {
            return nameOffset
        }

        return methodByteRange.location
    }

    private func containsSingleLineClosure(dictionary: [String: SourceKitRepresentable],
                                           endPosition: Int,
                                           file: File) -> Bool {
        let contents = file.contents.bridge()

        guard let closure = trailingClosure(dictionary: dictionary, file: file),
            let start = closure.bodyOffset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: start),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: endPosition) else {
                return false
        }

        return startLine == endLine
    }

    private func trailingClosure(dictionary: [String: SourceKitRepresentable],
                                 file: File) -> [String: SourceKitRepresentable]? {
        let arguments = dictionary.enclosedArguments
        let closureArguments = filterClosureArguments(arguments, file: file)

        if closureArguments.count == 1,
            closureArguments.last?.bridge() == arguments.last?.bridge() {
            return closureArguments.last
        }

        return nil
    }

    private func filterClosureArguments(_ arguments: [[String: SourceKitRepresentable]],
                                        file: File) -> [[String: SourceKitRepresentable]] {
        return arguments.filter { argument in
            guard let offset = argument.bodyOffset,
                let length = argument.bodyLength,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
                let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
                match.location == range.location else {
                    return false
            }

            return true
        }
    }
}
