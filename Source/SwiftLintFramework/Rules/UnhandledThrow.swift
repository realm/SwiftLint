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
            "func f() throws {\n throw anError \n}\n",
            "func f() throws -> Any {\n throw anError \n}\n"
        ],
        triggeringExamples: [
            "func f() throws {\n \n}\n",
            "func f() throws -> Any {\n \n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let matches = file.match(pattern: "(func).+(throws).+(throw)\\s", excludingSyntaxKinds: [])

        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

}
