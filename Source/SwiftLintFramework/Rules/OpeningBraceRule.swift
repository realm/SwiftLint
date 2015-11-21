//
//  OpeningBraceRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/21/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct OpeningBraceRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration.",
        nonTriggeringExamples: [
            "func abc() {\n}",
            "[].map() { $0 }",
            "[].map({ })"
        ],
        triggeringExamples: [
            "func abc(){\n}",
            "func abc()\n\t{ }",
            "[].map(){ $0 }",
            "[].map( { } )"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "((?:[^( ]|[\\t\\n\\f\\r (] )\\{)"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map { range in
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: range.location))
        }
    }
}
