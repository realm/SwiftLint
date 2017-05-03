//
//  SwitchCaseOnNewlineRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func wrapInSwitch(_ str: String) -> String {
    return "switch foo {\n  \(str)\n}\n"
}

public struct SwitchCaseOnNewlineRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_on_newline",
        name: "Switch Case on Newline",
        description: "Cases inside a switch should always be on a newline",
        nonTriggeringExamples: [
            "/*case 1: */return true",
            "//case 1:\n return true",
            "let x = [caseKey: value]",
            "let x = [key: .default]",
            "if case let .someEnum(value) = aFunction([key: 2]) { }",
            "guard case let .someEnum(value) = aFunction([key: 2]) { }",
            "for case let .someEnum(value) = aFunction([key: 2]) { }",
            "enum Environment {\n case development\n}",
            "enum Environment {\n case development(url: URL)\n}",
            "enum Environment {\n case development(url: URL) // staging\n}"
        ] + [
            "case 1:\n return true",
            "default:\n return true",
            "case let value:\n return true",
            "case .myCase: // error from network\n return true",
            "case let .myCase(value) where value > 10:\n return false",
            "case let .myCase(value)\n where value > 10:\n return false",
            "case let .myCase(code: lhsErrorCode, description: _)\n where lhsErrorCode > 10:\n return false",
            "case #selector(aFunction(_:)):\n return false\n"
        ].map(wrapInSwitch),
        triggeringExamples: [
            "↓case 1: return true",
            "↓case let value: return true",
            "↓default: return true",
            "↓case \"a string\": return false",
            "↓case .myCase: return false // error from network",
            "↓case let .myCase(value) where value > 10: return false",
            "↓case #selector(aFunction(_:)): return false\n",
            "↓case let .myCase(value)\n where value > 10: return false",
            "↓case .first,\n .second: return false"
        ].map(wrapInSwitch)
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .case,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let lastElement = dictionary.elements.last,
            let lastElementOffset = lastElement.offset,
            let lastElementLength = lastElement.length,
            case let start = lastElementOffset + lastElementLength,
            case let rangeLength = offset + length - start,
            case let byteRange = NSRange(location: start, length: rangeLength),
            let firstToken = firstNonCommentToken(inByteRange: byteRange, file: file),
            let (tokenLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: firstToken.offset),
            let (caseEndLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: start),
            tokenLine == caseEndLine else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func firstNonCommentToken(inByteRange byteRange: NSRange, file: File) -> SyntaxToken? {
        return file.syntaxMap.tokens(inByteRange: byteRange).first { token -> Bool in
            guard let kind = SyntaxKind(rawValue: token.type) else {
                return false
            }

            return !SyntaxKind.commentKinds().contains(kind)
        }
    }
}
