//
//  UnusedOptionalBindingRule.swift
//  SwiftLint
//
//  Created by Rafael Machado on 1/5/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnusedOptionalBindingRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_optional_binding",
        name: "Unused Optional Binding",
        description: "Prefer `!= nil` over `let _ =`",
        nonTriggeringExamples: [
            "if let bar = Foo.optionalValue {\n" +
            "}\n",
            "if let (_, second) = getOptionalTuple() {\n" +
            "}\n"
        ],
        triggeringExamples: [
            "if let ↓_ = Foo.optionalValue {\n" +
            "}\n",
            "if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {\n" +
            "}\n",
            "guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {\n" +
            "}\n",
            "if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue2 = getOptionalTuple() {\n" +
            "}\n"
        ]
    )

    public func validateFile(_ file: File,
                             kind: StatementKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .if || kind == .guard else {
                return []
        }

        return violationRanges(file: file).map {
            print((file.contents as NSString).substring(with: $0))
            return StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(file: File) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds()
        let underscorePattern = "(\\b_\\b)"
        let parenthesesPattern = "\\([^)]*\\)"
        let pattern = underscorePattern + "|" + parenthesesPattern

        return file.matchPattern(pattern,
                                 excludingSyntaxKinds: kinds,
                                 excludingPattern: parenthesesPattern)
    }

    private func isUnderscore(file: File, token: SyntaxToken) -> Bool {
        guard SyntaxKind(rawValue: token.type) == .keyword else {
            return false
        }
        let contents = file.contents.bridge()
        return contents.substringWithByteRange(start: token.offset, length: token.length) == "_"
    }
}
