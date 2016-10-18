//
//  SwitchCaseOnNewlineRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/15/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SwitchCaseOnNewlineRule: ConfigurationProviderRule, Rule, OptInRule {
    public let configurationDescription = "N/A"
    public var configuration = SeverityConfiguration(.Warning)

    public init() { }

    public static let description = RuleDescription(
        identifier: "switch_case_on_newline",
        name: "Switch Case on Newline",
        description: "Cases inside a switch should always be on a newline",
        nonTriggeringExamples: [
            "case 1:\n return true",
            "default:\n return true",
            "case let value:\n return true",
            "/*case 1: */return true",
            "//case 1:\n return true",
            "let x = [caseKey: value]",
            "let x = [key: .default]",
            "if case let .someEnum(value) = aFunction([key: 2]) {",
            "guard case let .someEnum(value) = aFunction([key: 2]) {",
            "for case let .someEnum(value) = aFunction([key: 2]) {"
        ],
        triggeringExamples: [
            "case 1: return true",
            "case let value: return true",
            "default: return true",
            "case \"a string\": return false"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(case[^\n]*|default):[^\\S\n]*[^\n]"
        return file.rangesAndTokensMatching(pattern).filter { range, tokens in
            guard let firstToken = tokens.first where tokenIsKeyword(firstToken) else {
                return false
            }

            let tokenString = contentForToken(firstToken, file: file)
            guard ["case", "default"].contains(tokenString) else {
                return false
            }

            // check if the first token in the line is `case`
            let lineAndCharacter = file.contents.lineAndCharacterForByteOffset(range.location)
            guard let (lineNumber, _) = lineAndCharacter else {
                return false
            }

            let line = file.lines[lineNumber - 1]
            let lineTokens = file.syntaxMap.tokensIn(line.byteRange).filter(tokenIsKeyword)

            guard let firstLineToken = lineTokens.first else {
                return false
            }

            let firstTokenInLineString = contentForToken(firstLineToken, file: file)
            return firstTokenInLineString == tokenString
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location))
        }
    }

    private func tokenIsKeyword(token: SyntaxToken) -> Bool {
        return SyntaxKind(rawValue: token.type) == .Keyword
    }

    private func contentForToken(token: SyntaxToken, file: File) -> String {
        return file.contents.substringWithByteRange(start: token.offset,
                                                    length: token.length) ?? ""
    }
}
