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
            "let x = [key: .default]"
        ],
        triggeringExamples: [
            "case 1: return true",
            "case let value: return true",
            "default: return true",
            "case \"a string\": return false"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(case[^\n]*|default):[^\\S\n]*[^\n]+"
        return file.rangesAndTokensMatching(pattern).filter { range, tokens in
            guard let firstToken = tokens.first
                where SyntaxKind(rawValue: firstToken.type) == .Keyword else {
                    return false
            }

            let tokenString = contentForToken(firstToken, file: file)
            return ["case", "default"].contains(tokenString)
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, byteOffset: $0.0.location))
        }
    }

    private func contentForToken(token: SyntaxToken, file: File) -> String {
        return file.contents.substringWithByteRange(start: token.offset,
                                                    length: token.length) ?? ""
    }
}
