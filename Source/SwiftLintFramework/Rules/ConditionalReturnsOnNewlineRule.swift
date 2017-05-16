//
//  ConditionalReturnsOnNewlineRule.swift
//  SwiftLint
//
//  Created by Rohan Dhaimade on 12/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ConditionalReturnsOnNewlineRule: ConfigurationProviderRule, Rule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        nonTriggeringExamples: [
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}",
            "if true else {\n return true\n}",
            "if true,\n let x = true else {\n return true\n}",
            "if textField.returnKeyType == .Next {",
            "if true { // return }",
            "/*if true { */ return }"
        ],
        triggeringExamples: [
            "↓guard true else { return }",
            "↓if true { return }",
            "↓if true { break } else { return }",
            "↓if true { break } else {       return }",
            "↓if true { return \"YES\" } else { return \"NO\" }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "(guard|if)[^\n]*return"
        return file.rangesAndTokens(matching: pattern).filter { _, tokens in
            guard let firstToken = tokens.first, let lastToken = tokens.last,
                SyntaxKind(rawValue: firstToken.type) == .keyword &&
                    SyntaxKind(rawValue: lastToken.type) == .keyword else {
                        return false
            }

            return ["if", "guard"].contains(content(for: firstToken, file: file)) &&
                content(for: lastToken, file: file) == "return"
        }.map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location))
        }
    }

    private func content(for token: SyntaxToken, file: File) -> String {
        return file.contents.bridge().substringWithByteRange(start: token.offset, length: token.length) ?? ""
    }
}
