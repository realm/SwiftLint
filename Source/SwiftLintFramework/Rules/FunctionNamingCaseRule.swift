//
//  FunctionNamingCaseRule.swift
//  SwiftLint
//
//  Created by Paul Williamson on 18/12/2015.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FunctionNamingCaseRule: Rule {
    public static let description = RuleDescription(
        identifier: "function_naming_case",
        name: "Function Naming Case",
        description: "Function names should begin with a lower case letter.",
        nonTriggeringExamples: [
            "func doSomething() { }"
        ],
        triggeringExamples: [
            "func DoSomething() { }"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "func\\s+[A-Z]"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }
}
