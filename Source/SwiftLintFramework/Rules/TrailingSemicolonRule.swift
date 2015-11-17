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
        triggeringExamples: [ "let a = 0;\n" ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.filter { $0.content.hasSuffix(";") }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file.path, line: $0.index),
                reason: "Line #\($0.index) should have no trailing semicolon")
        }
    }
}
