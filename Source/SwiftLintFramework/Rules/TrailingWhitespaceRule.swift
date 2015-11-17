//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingWhitespaceRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "// \n" ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.filter {
            $0.content.hasTrailingWhitespace()
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file.path, line: $0.index))
        }
    }
}
