//
//  ForceTryRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/17/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ForceTryRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_try",
        name: "Force Try",
        description: "Force tries should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func a() throws {}; do { try a() } catch {}"
        ],
        triggeringExamples: [
            "func a() throws {}; ↓try! a()"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "try!", with: [.keyword]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
