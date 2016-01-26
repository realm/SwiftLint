//
//  EmptyCountRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct EmptyCountRule: ConfigProviderRule, OptInRule {
    public var config = SeverityConfig(.Error)

    public init() { }

    public static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero.",
        nonTriggeringExamples: [
            Trigger("var count = 0\n"),
            Trigger("[Int]().isEmpty\n"),
            Trigger("[Int]().count > 1\n"),
            Trigger("[Int]().count == 1\n")
        ],
        triggeringExamples: [
            Trigger("[Int]().count == 0\n"),
            Trigger("[Int]().count > 0\n"),
            Trigger("[Int]().count != 0\n")
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "count\\s*(==|!=|<|<=|>|>=)\\s*0"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: config.severity, location: Location(file: file, byteOffset: $0.location))
        }
    }
}
