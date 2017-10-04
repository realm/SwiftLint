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
    public var configuration = UnusedOptionalBindingConfiguration(ignoreOptionalTry: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_optional_binding",
        name: "Unused Optional Binding",
        description: "Prefer `!= nil` over `let _ =`",
        kind: .style,
        nonTriggeringExamples: [
            "if let bar = Foo.optionalValue {\n" +
            "}\n",
            "if let (_, second) = getOptionalTuple() {\n" +
            "}\n",
            "if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {\n" +
            "}\n",
            "if foo() { let _ = bar() }\n",
            "if foo() { _ = bar() }\n",
            "if case .some(_) = self {}",
            "if let point = state.find({ _ in true }) {}"
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
            "}\n",
            "func foo() {\nif let ↓_ = bar {\n}\n",
            "if case .some(let ↓_) = self {}"
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let conditionKind = "source.lang.swift.structure.elem.condition_expr"
        guard kind == .if || kind == .guard else {
            return []
        }

        let elements = dictionary.elements.filter { $0.kind == conditionKind }
        return elements.flatMap { element -> [StyleViolation] in
            guard let offset = element.offset,
                let length = element.length,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length) else {
                    return []
            }

            return violations(in: range, of: file, with: kind).map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
        }
    }

    private func violations(in range: NSRange, of file: File, with kind: StatementKind) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds

        let underscorePattern = "(_\\s*[=,)]\\s*(try\\?)?)"
        let underscoreTuplePattern = "(\\((\\s*[_,]\\s*)+\\)\\s*=\\s*(try\\?)?)"
        let letUnderscore = "let\\s+(\(underscorePattern)|\(underscoreTuplePattern))"

        let matches = file.matchesAndSyntaxKinds(matching: letUnderscore, range: range)

        return matches
            .filter { $0.1.filter(kinds.contains).isEmpty }
            .filter { kind != .guard || !containsOptionalTry(at: $0.0.range, of: file) }
            .map { $0.0.range(at: 1) }
    }

    private func containsOptionalTry(at range: NSRange, of file: File) -> Bool {
        guard configuration.ignoreOptionalTry else {
            return false
        }

        let matches = file.match(pattern: "try?", with: [.keyword], range: range)
        return !matches.isEmpty
    }
}
