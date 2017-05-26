//
//  LargeTupleRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum LargeTupleRuleError: Error {
    case unbalencedParentheses
}

private enum RangeKind {
    case tuple
    case generic
}

public struct LargeTupleRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)

    public init() {}

    public static let description = RuleDescription(
        identifier: "large_tuple",
        name: "Large Tuple",
        description: "Tuples shouldn't have too many members. Create a custom type instead.",
        nonTriggeringExamples: [
            "let foo: (Int, Int)\n",
            "let foo: (start: Int, end: Int)\n",
            "let foo: (Int, (Int, String))\n",
            "func foo() -> (Int, Int)\n",
            "func foo() -> (Int, Int) {}\n",
            "func foo(bar: String) -> (Int, Int)\n",
            "func foo(bar: String) -> (Int, Int) {}\n",
            "func foo() throws -> (Int, Int)\n",
            "func foo() throws -> (Int, Int) {}\n",
            "let foo: (Int, Int, Int) -> Void\n",
            "var completionHandler: ((_ data: Data?, _ resp: URLResponse?, _ e: NSError?) -> Void)!\n",
            "func getDictionaryAndInt() -> (Dictionary<Int, String>, Int)?\n",
            "func getGenericTypeAndInt() -> (Type<Int, String, Float>, Int)?\n"
        ],
        triggeringExamples: [
            "↓let foo: (Int, Int, Int)\n",
            "↓let foo: (start: Int, end: Int, value: String)\n",
            "↓let foo: (Int, (Int, Int, Int))\n",
            "func foo(↓bar: (Int, Int, Int))\n",
            "func foo() -> ↓(Int, Int, Int)\n",
            "func foo() -> ↓(Int, Int, Int) {}\n",
            "func foo(bar: String) -> ↓(Int, Int, Int)\n",
            "func foo(bar: String) -> ↓(Int, Int, Int) {}\n",
            "func foo() throws -> ↓(Int, Int, Int)\n",
            "func foo() throws -> ↓(Int, Int, Int) {}\n",
            "func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}\n",
            "func getDictionaryAndInt() -> (Dictionary<Int, ↓(String, String, String)>, Int)?\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let offsets = violationOffsetsForTypes(in: file, dictionary: dictionary, kind: kind) +
            violationOffsetsForFunctions(in: file, dictionary: dictionary, kind: kind)

        return offsets.flatMap { arg in
            let (location, size) = arg
            for parameter in configuration.params where size > parameter.value {
                let reason = "Tuples should have at most \(configuration.warning) members."
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: parameter.severity,
                                      location: Location(file: file, byteOffset: location),
                                      reason: reason)
            }

            return nil
        }
    }

    private func violationOffsetsForTypes(in file: File, dictionary: [String: SourceKitRepresentable],
                                          kind: SwiftDeclarationKind) -> [(offset: Int, size: Int)] {
        let kinds = SwiftDeclarationKind.variableKinds().filter { $0 != .varLocal }
        guard kinds.contains(kind),
            let type = dictionary.typeName,
            let offset = dictionary.offset else {
                return []
        }

        let sizes = violationOffsets(for: type).map { $0.1 }
        return sizes.max().flatMap { [(offset: offset, size: $0)] } ?? []
    }

    private func violationOffsetsForFunctions(in file: File, dictionary: [String: SourceKitRepresentable],
                                              kind: SwiftDeclarationKind) -> [(offset: Int, size: Int)] {
        let contents = file.contents.bridge()
        guard SwiftDeclarationKind.functionKinds().contains(kind),
            let returnRange = returnRangeForFunction(dictionary: dictionary),
            let returnSubstring = contents.substringWithByteRange(start: returnRange.location,
                                                                  length: returnRange.length) else {
                return []
        }

        let offsets = violationOffsets(for: returnSubstring, initialOffset: returnRange.location)
        return offsets.sorted(by: { $0.offset < $1.offset })
    }

    private func violationOffsets(for text: String, initialOffset: Int = 0) -> [(offset: Int, size: Int)] {
        guard let ranges = try? parenthesesRanges(in: text) else {
            return []
        }

        var text = text.bridge()
        var offsets = [(offset: Int, size: Int)]()

        for (range, kind) in ranges {
            let substring = text.substring(with: range)
            if kind != .generic,
                let byteRange = text.NSRangeToByteRange(start: range.location, length: range.length),
                !containsReturnArrow(in: text.bridge(), range: range) {

                let size = substring.components(separatedBy: ",").count
                let offset = byteRange.location + initialOffset
                offsets.append((offset: offset, size: size))
            }

            let replacement = String(repeating: " ", count: substring.bridge().length)
            text = text.replacingCharacters(in: range, with: replacement).bridge()
        }

        return offsets
    }

    private func returnRangeForFunction(dictionary: [String: SourceKitRepresentable]) -> NSRange? {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let length = dictionary.length,
            let offset = dictionary.offset else {
                return nil
        }

        let start = nameOffset + nameLength
        let end = dictionary.bodyOffset ?? length + offset

        guard end - start > 0 else {
            return nil
        }

        return NSRange(location: start, length: end - start)
    }

    private func parenthesesRanges(in text: String) throws -> [(NSRange, RangeKind)] {
        var stack = [(Int, String)]()
        var balanced = true
        var ranges = [(NSRange, RangeKind)]()

        let nsText = text.bridge()
        let parenthesesAndAngleBrackets = CharacterSet(charactersIn: "()<>")
        var index = 0
        let length = nsText.length

        while balanced {
            let searchRange = NSRange(location: index, length: length - index)
            let range = nsText.rangeOfCharacter(from: parenthesesAndAngleBrackets,
                                                options: [.literal], range: searchRange)
            if range.location == NSNotFound {
                break
            }

            index = NSMaxRange(range)
            let symbol = nsText.substring(with: range)

            // skip return arrows
            if symbol == ">",
                case let arrowRange = nsText.range(of: "->", options: [.literal], range: searchRange),
                arrowRange.intersects(range) {
                continue
            }

            if symbol == "(" || symbol == "<" {
                stack.append((range.location, symbol))
            } else if let (startIdx, previousSymbol) = stack.popLast(),
                isBalanced(currentSymbol: symbol, previousSymbol: previousSymbol) {

                let range = NSRange(location: startIdx, length: range.location - startIdx + 1)
                let kind: RangeKind = symbol == ")" ? .tuple : .generic
                ranges.append((range, kind))
            } else {
                balanced = false
            }
        }

        guard balanced && stack.isEmpty else {
            throw LargeTupleRuleError.unbalencedParentheses
        }

        return ranges
    }

    private func isBalanced(currentSymbol: String, previousSymbol: String) -> Bool {
        return (currentSymbol == ")" && previousSymbol == "(") ||
            (currentSymbol == ">" && previousSymbol == "<")
    }

    private func containsReturnArrow(in text: String, range: NSRange) -> Bool {
        let arrowRegex = regex("\\A\\s*->")
        let start = NSMaxRange(range)
        let restOfStringRange = NSRange(location: start, length: text.bridge().length - start)

        return arrowRegex.firstMatch(in: text, options: [], range: restOfStringRange) != nil
    }

}
