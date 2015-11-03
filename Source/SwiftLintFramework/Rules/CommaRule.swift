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
    public init() { }
    public let identifier = "comma"

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(\\,[^\\s])|(\\s\\,)"
        let excludingKinds = [SyntaxKind.Comment, .CommentMark, .CommentURL,
            .DocComment, .DocCommentField, .String]

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).flatMap { match in
            return StyleViolation(type: .Comma,
                location: Location(file: file, offset: match.location),
                severity: .Warning,
                reason: "One space before and no after must be present next to " +
                "commas")
        }
    }

    public let example = RuleExample(
        ruleName: "Comma Spacing Rule",
        ruleDescription: "One space before and no after must be present next to " +
        "any comma.",
        nonTriggeringExamples: [
            "func abc(a: String, b: String) { }",
            "abc(a: \"string\", b: \"string\"",
            "enum a { case a, b, c }"
        ],
        triggeringExamples: [
            "func abc(a: String ,b: String) { }",
            "abc(a: \"string\",b: \"string\"",
            "enum a { case a ,b }"
        ]
    )
}
