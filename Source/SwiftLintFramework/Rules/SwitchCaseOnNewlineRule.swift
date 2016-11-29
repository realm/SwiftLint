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
            "for case let .someEnum(value) = aFunction([key: 2]) {",
            "case .myCase: // error from network",
            "case let .myCase(value) where value > 10:\n return false",
            "enum Environment {\n case development\n}",
            "enum Environment {\n case development(url: URL)\n}",
            "enum Environment {\n case development(url: URL) // staging\n}"
        ],
        triggeringExamples: [
            "case 1: return true",
            "case let value: return true",
            "default: return true",
            "case \"a string\": return false",
            "case .myCase: return false // error from network",
            "case let .myCase(value) where value > 10: return false"
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
            let allLineTokens = file.syntaxMap.tokensIn(line.byteRange)
            let lineTokens = allLineTokens.filter(tokenIsKeyword)

            guard let firstLineToken = lineTokens.first else {
                return false
            }

            let firstTokenInLineString = contentForToken(firstLineToken, file: file)
            guard firstTokenInLineString == tokenString else {
                return false
            }

            return isViolation(allLineTokens, file: file, line: line)
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location))
        }
    }

    private func tokenIsKeyword(token: SyntaxToken) -> Bool {
        return SyntaxKind(rawValue: token.type) == .Keyword
    }

    private func tokenIsComment(token: SyntaxToken) -> Bool {
        guard let kind = SyntaxKind(rawValue: token.type) else {
            return false
        }

        return SyntaxKind.commentKinds().contains(kind)
    }

    private func contentForToken(token: SyntaxToken, file: File) -> String {
        return contentForRange(token.offset, length: token.length, file: file)
    }

    private func contentForRange(start: Int, length: Int, file: File) -> String {
        return file.contents.substringWithByteRange(start: start, length: length) ?? ""
    }

    private func trailingComments(tokens: [SyntaxToken]) -> [SyntaxToken] {
        var lastWasComment = true
        return tokens.reverse().filter { token in
            let shouldRemove = lastWasComment && tokenIsComment(token)
            if !shouldRemove {
                lastWasComment = false
            }
            return shouldRemove
        }.reverse()
    }

    private func isViolation(lineTokens: [SyntaxToken], file: File, line: Line) -> Bool {
        let trailingCommentsTokens = trailingComments(lineTokens)

        guard let firstToken = lineTokens.first where !isEnumCase(file, token: firstToken) else {
            return false
        }

        guard let firstComment = trailingCommentsTokens.first,
            lastComment = trailingCommentsTokens.last else {
                return true
        }

        let commentsLength = (lastComment.offset + lastComment.length) - firstComment.offset
        let line = contentForRange(line.byteRange.location,
                                   length: line.byteRange.length - commentsLength, file: file)
        let cleaned = line.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())

        return !cleaned.hasSuffix(":")
    }

    private func isEnumCase(file: File, token: SyntaxToken) -> Bool {
        let kinds = file.structure.kindsFor(token.offset).flatMap {
            SwiftDeclarationKind(rawValue: $0.kind)
        }

        // it's a violation unless it's actually an enum case declaration
        return kinds.contains(.Enumcase)
    }
}
