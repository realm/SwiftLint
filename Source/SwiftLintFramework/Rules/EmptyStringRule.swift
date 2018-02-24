//
//  EmptyStringRule.swift
//  SwiftLint
//
//  Created by Davide Sibilio on 02/22/18.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct EmptyStringRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to \"\".",
        kind: .performance,
        nonTriggeringExamples: [
            "myString.isEmpty",
            "!myString.isEmpy"
        ],
        triggeringExamples: [
            "myString ↓== \"\"",
            "myString ↓!= \"\""
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\b\\s*(==|!=)\\s*\"\""
        let excludingKinds = SyntaxKind.commentKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
