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
            "let foo: (Int, Int, Int) -> Void\n"
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
            "func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let offsets = violationOffsetsForTypes(in: file, dictionary: dictionary, kind: kind) +
            violationOffsetsForFunctions(in: file, dictionary: dictionary, kind: kind)

        return offsets.flatMap { location, size in
            for parameter in configuration.params where size > parameter.value {
                let reason = "Tuples should have at most \(parameter.value) members."
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
            let offset = dictionary.offset,
            let ranges = try? parenthesesRanges(in: type) else {
                return []
        }

        var text = type.bridge()
        var maxSize: Int?
        for range in ranges {
            let substring = text.substring(with: range)
            let size = substring.components(separatedBy: ",").count
            maxSize = max(size, maxSize ?? .min)

            let replacement = String(repeating: " ", count: substring.bridge().length)
            text = text.replacingCharacters(in: range, with: replacement).bridge()
        }

        return maxSize.flatMap { [(offset: offset, size: $0)] } ?? []
    }

    private func violationOffsetsForFunctions(in file: File, dictionary: [String: SourceKitRepresentable],
                                              kind: SwiftDeclarationKind) -> [(offset: Int, size: Int)] {
        let contents = file.contents.bridge()
        guard SwiftDeclarationKind.functionKinds().contains(kind),
            let returnRange = returnRangeForFunction(dictionary: dictionary),
            let returnSubstring = contents.substringWithByteRange(start: returnRange.location,
                                                                  length: returnRange.length),
            let ranges = try? parenthesesRanges(in: returnSubstring) else {
                return []
        }

        var text = returnSubstring.bridge()
        var offsets = [(offset: Int, size: Int)]()

        for range in ranges {
            let substring = text.substring(with: range)
            if let byteRange = text.NSRangeToByteRange(start: range.location, length: range.length) {
                let size = substring.components(separatedBy: ",").count
                let offset = byteRange.location + returnRange.location
                offsets.append((offset: offset, size: size))
            }

            let replacement = String(repeating: " ", count: substring.bridge().length)
            text = text.replacingCharacters(in: range, with: replacement).bridge()
        }

        return offsets.sorted(by: { $0.offset < $1.offset })
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

    private func parenthesesRanges(in text: String) throws -> [NSRange] {
        var stack = [Int]()
        var balanced = true
        var ranges = [NSRange]()

        let nsText = text.bridge()
        let parentheses = CharacterSet(charactersIn: "()")
        var index = 0
        let length = nsText.length

        while balanced {
            let searchRange = NSRange(location: index, length: length - index)
            let range = nsText.rangeOfCharacter(from: parentheses, options: [], range: searchRange)
            if range.location == NSNotFound {
                break
            }

            index = NSMaxRange(range)
            let symbol = nsText.substring(with: range)

            if symbol == "(" {
                stack.append(range.location)
            } else if let startIdx = stack.popLast() {
                ranges.append(NSRange(location: startIdx, length: range.location - startIdx + 1))
            } else {
                balanced = false
            }
        }

        guard balanced && stack.isEmpty else {
            throw LargeTupleRuleError.unbalencedParentheses
        }

        let arrowRegex = regex("\\s*->")
        return ranges.filter { range in
            let start = NSMaxRange(range)
            let restOfStringRange = NSRange(location: start, length: length - start)
            if let match = arrowRegex.firstMatch(in: text, options: [], range: restOfStringRange)?.range,
                match.location == start {
                return false
            }

            return true
        }
    }

}
