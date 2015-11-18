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

    public static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the same line, one space after the previous " +
                     "declaration.",
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

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "((?:\\}|[\\s] |[\\n\\t\\r])(?:else|catch))"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).flatMap { range in
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: range.location))
        }
    }
}
