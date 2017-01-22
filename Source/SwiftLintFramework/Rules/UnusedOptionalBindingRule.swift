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
            "}\n",
            "if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {\n" +
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
            "if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n",
            "if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {\n" +
            "}\n"
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .if || kind == .guard,
            let offset = dictionary.offset,
            let length = dictionary.length,
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

        let underlineOutsideParenthesis = "(?<=[^(]\\s)_(?=\\s[^)])"
        let underlineInsideParenthesis = "\\((\\s*[_,]\\s*)+\\)"
        let pattern = underlineOutsideParenthesis + "|" + underlineInsideParenthesis
        return file.match(pattern: pattern,
                          excludingSyntaxKinds: kinds,
                          range: range)
    }
}
