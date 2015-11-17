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
        description: "Check whether there is a space before opening brace and it is on the same " +
        "line.",
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

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map { match in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: match.location),
                reason: "Opening brace after a space and on same line as declaration")
        }
    }
}
