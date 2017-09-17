//
//  IsDisjointRule.swift
//  SwiftLint
//
//  Created by JP Simard on 8/21/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct IsDisjointRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "is_disjoint",
        name: "Is Disjoint",
        description: "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)",
            "let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)",
            "_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)",
            "_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)"
        ],
        triggeringExamples: [
            "_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty",
            "let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\bintersection\\(\\S+\\)\\.isEmpty"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
