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

    public init() { }

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
            "/*if true { */ return }",
        ],
        triggeringExamples: [
            "guard true else { return }",
            "if true { return }",
            "if true { break } else { return }",
            "if true { break } else {       return }",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(guard|if)[^\n]*return[^\n]\n*"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.rangesAndTokensMatching(pattern).filter { range, tokens in
            let kinds = tokens.flatMap { SyntaxKind(rawValue: $0.type) }

            guard kinds.filter(excludingKinds.contains).isEmpty else {
                return false
            }

            let nsString: NSString = file.contents
            return !tokens.filter { token in
                guard SyntaxKind(rawValue: token.type) == .Keyword else {
                    return false
                }

                let tokenRange = NSRange(location: token.offset, length: token.length)
                let tokenString = nsString.substringWithRange(tokenRange)
                return tokenString == "return"
            }.isEmpty
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, byteOffset: $0.0.location))
        }
    }
}
