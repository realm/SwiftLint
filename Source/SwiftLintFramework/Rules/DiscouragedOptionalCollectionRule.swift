//
//  DiscouragedOptinalCollection.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/10/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DiscouragedOptionalCollectionRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_optional_collection",
        name: "Discouraged Optional Collection",
        description: "Prefer empty collection over optional collection.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "var foo: [Int] = []",
            "var foo: [String: Int] = [:]",
            "var foo: Set<String> = []",
            "func foo() -> [] {}",
            "func foo() -> [String: String] {}",
            "func foo(input: [String: String] = [:]) {}",
            "var foo: [String: [String: Int]] = [:]"
        ],
        triggeringExamples: [
            "var foo: ↓[Int]?",
            "var foo: ↓[String: Int]?",
            "var foo: ↓Set<String>?",
            "func foo() -> ↓[]? {}",
            "func foo() -> ↓[String: String]? {}",
            "func foo(input: ↓[String: String]?) {}",
            "func foo(input: ↓[\n" +
            "                  String: String\n" +
            "                 ]?) {}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let matches = violationMatchesLocations(in: file)

        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0))
        }
    }

    private func violationMatchesLocations(in file: File) -> [Int] {
        let bracketPattern = "\\[(.*[^\\]])?\\]\\?"
        let setPattern = "Set<(.*[^>])?>\\?"
        let pattern = [bracketPattern, setPattern].joined(separator: "|")
        let excludingKinds = SyntaxKind.commentAndStringKinds

        return file
            .match(pattern: pattern)
            .filter { $1.filter(excludingKinds.contains).isEmpty }
            .map { $0.0.location }
    }
}
