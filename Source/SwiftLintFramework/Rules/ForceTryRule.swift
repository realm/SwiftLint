//
//  ForceTryRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ForceTryRule: Rule {

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_try",
        name: "Force Try",
        description: "Force tries should be avoided.",
        nonTriggeringExamples: [
            "func a() throws {}; do { try a() } catch {}"
        ],
        triggeringExamples: [
            "func a() throws {}; ↓try! a()"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("try!", withSyntaxKinds: [.Keyword]).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: .Error, location: Location(file: file, characterOffset: $0.location))
        }
    }
}
