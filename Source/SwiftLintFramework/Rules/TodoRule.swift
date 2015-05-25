//
//  TodoRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TodoRule: Rule {
    public init() {}

    public let identifier = "todo"

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("// (TODO|FIXME):", withSyntaxKinds: [.Comment]).map { range in
            return StyleViolation(type: .TODO,
                location: Location(file: file, offset: range.location),
                severity: .Low,
                reason: "TODOs and FIXMEs should be avoided")
        }
    }

    public let example = RuleExample(
        ruleName: "Todo Rule",
        ruleDescription: "This rule checks whether you removed all TODOs and FIXMEs.",
        nonTriggeringExamples: [
            "let string = \"// TODO:\"\n",
            "let string = \"// FIXME:\"\n"
        ],
        triggeringExamples: [
            "// TODO:\n",
            "// FIXME:\n"
        ]
    )
}
