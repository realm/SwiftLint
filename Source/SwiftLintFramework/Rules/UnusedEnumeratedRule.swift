//
//  UnusedEnumeratedRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/17/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnusedEnumeratedRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_enumerated",
        name: "Unused Enumerated",
        description: "When the index or the item is not used, `.enumerated()` can be removed.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "for (idx, foo) in bar.enumerated() { }\n",
            "for (_, foo) in bar.enumerated().something() { }\n",
            "for (_, foo) in bar.something() { }\n",
            "for foo in bar.enumerated() { }\n",
            "for foo in bar { }\n",
            "for (idx, _) in bar.enumerated().something() { }\n",
            "for (idx, _) in bar.something() { }\n",
            "for idx in bar.indices { }\n",
            "for (section, (event, _)) in data.enumerated() {}\n"
        ],
        triggeringExamples: [
            "for (↓_, foo) in bar.enumerated() { }\n",
            "for (↓_, foo) in abc.bar.enumerated() { }\n",
            "for (↓_, foo) in abc.something().enumerated() { }\n",
            "for (idx, ↓_) in bar.enumerated() { }\n"
        ]
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == .forEach,
            isEnumeratedCall(dictionary: dictionary),
            let byteRange = byteRangeForVariables(dictionary: dictionary),
            case let tokens = file.syntaxMap.tokens(inByteRange: byteRange),
            tokens.count == 2,
            let lastToken = tokens.last,
            case let firstTokenIsUnderscore = isTokenUnderscore(tokens[0], file: file),
            case let lastTokenIsUnderscore = isTokenUnderscore(lastToken, file: file),
            firstTokenIsUnderscore || lastTokenIsUnderscore else {
                return []
        }

        let offset: Int
        let reason: String
        if firstTokenIsUnderscore {
            offset = tokens[0].offset
            reason = "When the index is not used, `.enumerated()` can be removed."
        } else {
            offset = lastToken.offset
            reason = "When the item is not used, `.indices` should be used instead of `.enumerated()`."
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset),
                           reason: reason)
        ]
    }

    private func isTokenUnderscore(_ token: SyntaxToken, file: File) -> Bool {
        return token.length == 1 &&
            SyntaxKind(rawValue: token.type) == .keyword &&
            isUnderscore(file: file, token: token)
    }

    private func isEnumeratedCall(dictionary: [String: SourceKitRepresentable]) -> Bool {
        for subDict in dictionary.substructure {
            guard let kindString = subDict.kind,
                SwiftExpressionKind(rawValue: kindString) == .call,
                let name = subDict.name else {
                    continue
            }

            if name.hasSuffix(".enumerated") {
                return true
            }
        }

        return false
    }

    private func byteRangeForVariables(dictionary: [String: SourceKitRepresentable]) -> NSRange? {
        let expectedKind = "source.lang.swift.structure.elem.id"
        for subDict in dictionary.elements where subDict.kind == expectedKind {
            guard let offset = subDict.offset,
                let length = subDict.length else {
                continue
            }

            return NSRange(location: offset, length: length)
        }

        return nil
    }

    private func isUnderscore(file: File, token: SyntaxToken) -> Bool {
        let contents = file.contents.bridge()
        return contents.substringWithByteRange(start: token.offset, length: token.length) == "_"
    }
}
