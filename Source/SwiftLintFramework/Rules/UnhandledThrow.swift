//
//  UnhandledThrow.swift
//  SwiftLint
//
//  Created by Arthur Ariel Sabintsev on 2/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnhandledThrowRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unhandled_throw",
        name: "Unhandled Throw",
        description: "When a throwing function does not handle a throw, the `throws` keyword can be removed.",
        nonTriggeringExamples: [
            "func f() throws { throw .anError }",
            "func f() throws -> Any { throw .anError }"
        ],
        triggeringExamples: [
            "func f() throws { }\n",
            "func f() throws -> Any { }\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "/(func).+(throws)*$.+\\}/gm"

        let matches = file.rangesAndTokens(matching: pattern)

        print("TESTING UnhandledThrowRule", matches)

        return []
    }

}
