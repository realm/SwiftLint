//
//  Comma.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/22/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CommaRule: Rule {
    public static let description = RuleDescription(
        identifier: "comma",
        name: "Comma Spacing",
        description: "One space before and no after must be present next to any comma.",
        nonTriggeringExamples: [
            "func abc(a: String, b: String) { }",
            "abc(a: \"string\", b: \"string\"",
            "enum a { case a, b, c }"
        ],
        triggeringExamples: [
            "func abc(a: String↓ ,b: String) { }",
            "abc(a: \"string\"↓,b: \"string\"",
            "enum a { case a↓ ,b }"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(\\,[^\\s])|(\\s\\,)"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }
}
