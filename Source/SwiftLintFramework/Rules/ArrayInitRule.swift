//
//  ArrayInitRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 09/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ArrayInitRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "array_init",
        name: "Array Init",
        description: "Prefer using Array(seq) than seq.map { $0 } to convert a sequence into an Array.",
        kind: .lint,
        nonTriggeringExamples: [
            "Array(foo)\n",
            "foo.map { $0.0 }\n",
            "foo.map { $1 }\n",
            "foo.map { $0() }\n",
            "foo.map { ((), $0) }\n",
            "foo.map { $0! }\n",
            "foo.map { $0! /* force unwrap */ }\n"
        ],
        triggeringExamples: [
            "↓foo.map({ $0 })\n",
            "↓foo.map { $0 }\n",
            "↓foo.map { return $0 }\n",
            "↓foo.map { elem in\n" +
            "   elem\n" +
            "}\n",
            "↓foo.map { elem in\n" +
            "   return elem\n" +
            "}\n",
            "↓foo.map { (elem: String) in\n" +
                "   elem\n" +
            "}\n",
            "↓foo.map { elem -> String in\n" +
            "   elem\n" +
            "}\n",
            "↓foo.map { $0 /* a comment */ }\n"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call, let name = dictionary.name, name.hasSuffix(".map"),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let offset = dictionary.offset else {
                return []
        }

        let range = NSRange(location: bodyOffset, length: bodyLength)
        let tokens = file.syntaxMap.tokens(inByteRange: range).filter { token in
            guard let kind = SyntaxKind(rawValue: token.type) else {
                return false
            }

            return !SyntaxKind.commentKinds().contains(kind)
        }

        guard isShortParameterStyleViolation(file: file, tokens: tokens) ||
            isParameterStyleViolation(file: file, dictionary: dictionary, tokens: tokens),
            let lastToken = tokens.last,
            case let bodyEndPosition = bodyOffset + bodyLength,
            !containsTrailingContent(lastToken: lastToken, bodyEndPosition: bodyEndPosition, file: file) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func containsTrailingContent(lastToken: SyntaxToken,
                                         bodyEndPosition: Int,
                                         file: File) -> Bool {
        let lastTokenEnd = lastToken.offset + lastToken.length
        let remainingLength = bodyEndPosition - lastTokenEnd
        let nsstring = file.contents.bridge()
        let remainingRange = NSRange(location: lastTokenEnd, length: remainingLength)
        let remainingTokens = file.syntaxMap.tokens(inByteRange: remainingRange)
        let ranges = NSMutableIndexSet(indexesIn: remainingRange)

        for token in remainingTokens {
            ranges.remove(in: NSRange(location: token.offset, length: token.length))
        }

        var containsContent = false
        ranges.enumerateRanges(options: []) { range, stop in
            guard let substring = nsstring.substringWithByteRange(start: range.location, length: range.length) else {
                return
            }

            let set = CharacterSet(charactersIn: "{}").union(.whitespacesAndNewlines)
            let processedSubstring = substring.trimmingCharacters(in: set)
            if !processedSubstring.isEmpty {
                stop.pointee = true
                containsContent = true
            }
        }

        return containsContent
    }

    private func isShortParameterStyleViolation(file: File, tokens: [SyntaxToken]) -> Bool {
        let kinds = tokens.flatMap { SyntaxKind(rawValue: $0.type) }
        switch kinds {
        case [.identifier]:
            let identifier = file.contents(for: tokens[0])
            return identifier == "$0"
        case [.keyword, .identifier]:
            let keyword = file.contents(for: tokens[0])
            let identifier = file.contents(for: tokens[1])
            return keyword == "return" && identifier == "$0"
        default:
            return false
        }
    }

    private func isParameterStyleViolation(file: File, dictionary: [String: SourceKitRepresentable],
                                           tokens: [SyntaxToken]) -> Bool {
        let parameters = dictionary.enclosedVarParameters
        guard parameters.count == 1,
            let offset = parameters[0].offset,
            let length = parameters[0].length,
            let parameterName = parameters[0].name else {
                return false
        }

        let parameterEnd = offset + length
        let tokens = Array(tokens.filter { $0.offset >= parameterEnd }.drop { token in
            let isKeyword = SyntaxKind(rawValue: token.type) == .keyword
            return !isKeyword || file.contents(for: token) != "in"
        })

        let kinds = tokens.flatMap { SyntaxKind(rawValue: $0.type) }
        switch kinds {
        case [.keyword, .identifier]:
            let keyword = file.contents(for: tokens[0])
            let identifier = file.contents(for: tokens[1])
            return keyword == "in" && identifier == parameterName
        case [.keyword, .keyword, .identifier]:
            let firstKeyword = file.contents(for: tokens[0])
            let secondKeyword = file.contents(for: tokens[1])
            let identifier = file.contents(for: tokens[2])
            return firstKeyword == "in" && secondKeyword == "return" && identifier == parameterName
        default:
            return false
        }
    }
}

private func ~= (array: [SyntaxKind], value: [SyntaxKind]) -> Bool {
    return array == value
}

private extension File {
    func contents(for token: SyntaxToken) -> String? {
        return contents.bridge().substringWithByteRange(start: token.offset,
                                                        length: token.length)
    }
}
