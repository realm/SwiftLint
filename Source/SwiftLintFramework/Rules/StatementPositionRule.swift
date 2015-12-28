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
    public static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the same line, one space after the previous " +
                     "declaration.",
        nonTriggeringExamples: [
            "} else if {",
            "} else {",
            "} catch {",
            "\"}else{\"",
            "struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)",
            "struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"
        ],
        triggeringExamples: [
            "↓}else if {",
            "}↓  else {",
            "}↓\ncatch {",
            "}\n\t↓  catch {"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "((?:\\}|[\\s] |[\\n\\t\\r])\\b(?:else|catch))\\b"

        return file.matchPattern(pattern, withSyntaxKinds: [.Keyword]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }
}
