//
//  TrailingSemiColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingSemicolonRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons.",
        nonTriggeringExamples: [ "let a = 0\n" ],
        triggeringExamples: [
            "let a = 0;\n",
            "let a = 0;\nlet b = 1\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(";$", excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }
}
