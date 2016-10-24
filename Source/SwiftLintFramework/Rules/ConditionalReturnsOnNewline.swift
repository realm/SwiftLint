//
//  ConditionalReturnsOnNewline.swift
//  SwiftLint
//
//  Created by Rohan Dhaimade on 12/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ConditionalReturnsOnNewline: ConfigurationProviderRule, Rule, OptInRule {
    public let configurationDescription = "N/A"
    public var configuration = SeverityConfiguration(.Warning)

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
            "guard true else { return }",
            "if true { return }",
            "if true { break } else { return }",
            "if true { break } else {       return }",
            "if true { return \"YES\" } else { return \"NO\" }"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(guard|if)[^\n]*return"
        return file.rangesAndTokensMatching(pattern).filter { range, tokens in
            guard let firstToken = tokens.first, lastToken = tokens.last
                where SyntaxKind(rawValue: firstToken.type) == .Keyword &&
                    SyntaxKind(rawValue: lastToken.type) == .Keyword else {
                        return false
            }

            return ["if", "guard"].contains(contentForToken(firstToken, file: file)) &&
                contentForToken(lastToken, file: file) == "return"
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location))
        }
    }

    private func contentForToken(token: SyntaxToken, file: File) -> String {
        return file.contents.substringWithByteRange(start: token.offset,
                                                    length: token.length) ?? ""
    }
}
