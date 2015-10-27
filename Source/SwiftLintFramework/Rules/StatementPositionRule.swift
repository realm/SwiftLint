//
//  StatementPositionRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/22/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct StatementPositionRule: Rule {
    public init() {}
    public let identifier = "statement_position"

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "((?:\\}|[\\s] |[\\n\\t\\r])(?:else|catch))"
        let excludingKinds = [SyntaxKind.Comment, .CommentMark, .CommentURL,
            .DocComment, .DocCommentField, .String]

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).flatMap { match in
            return StyleViolation(type: .StatementPosition,
                location: Location(file: file, offset: match.location),
                severity: .Warning,
                reason: "Else and catch must be on the same line and one space " +
                    "after previous declaration")
        }
    }

    public let example = RuleExample(
        ruleName: "Statement Position Rule",
        ruleDescription: "This rule checks whether statements are correctly " +
            "positioned.",
        nonTriggeringExamples: [
            "} else if {",
            "} else {",
            "} catch {",
            "\"}else{\""
        ],
        triggeringExamples: [
            "}else if {",
            "}  else {",
            "}\ncatch {",
            "}\n\t  catch {"
        ]
    )
}
