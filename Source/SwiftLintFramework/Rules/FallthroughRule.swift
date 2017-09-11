//
//  FallthroughRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 09/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FallthroughRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "switch foo {\n" +
            "case .bar, .bar2, .bar3:\n" +
            "    something()\n" +
            "}"
        ],
        triggeringExamples: [
            "switch foo {\n" +
            "case .bar:\n" +
            "    ↓fallthrough\n" +
            "case .bar2:\n" +
            "    something()\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "fallthrough", with: [.keyword]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
