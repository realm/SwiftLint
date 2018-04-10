//
//  EmptyCountRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/17/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct EmptyCountRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero.",
        kind: .performance,
        nonTriggeringExamples: [
            "var count = 0\n",
            "[Int]().isEmpty\n",
            "[Int]().count > 1\n",
            "[Int]().count == 1\n",
            "discount == 0\n",
            "order.discount == 0\n"
        ],
        triggeringExamples: [
            "[Int]().↓count == 0\n",
            "[Int]().↓count > 0\n",
            "[Int]().↓count != 0\n",
            "↓count == 0\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\bcount\\s*(==|!=|<|<=|>|>=)\\s*0"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
