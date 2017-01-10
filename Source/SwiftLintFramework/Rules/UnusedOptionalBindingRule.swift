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
            "if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n",
            "if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n",
            "if let (_, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n"
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .if || kind == .guard,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        return violations(in: range, of: file).map {
            StyleViolation(ruleDescription: type(of: self).description, severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violations(in range: NSRange, of file: File) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds()
        let underscorePattern = "\\b_\\b"
        let parenthesesPattern = "\\([^)]*\\)"

        return file.match(pattern: underscorePattern,
                          range: range,
                          excludingSyntaxKinds: kinds,
                          excludingPattern: parenthesesPattern)
    }
}
