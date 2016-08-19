//
//  GuardReturnsOnNewline.swift
//  SwiftLint
//
//  Created by Rohan Dhaimade on 12/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct GuardReturnsOnNewline: Rule, OptInRule {
    public let configurationDescription = "N/A"

    public init() { }

    public init(configuration: AnyObject) { }

    public static let description = RuleDescription(
        identifier: "guard_returns_on_newline",
        name: "Guard Returns on Newline",
        description: "Guards should always return on the next line",
        nonTriggeringExamples: [
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}"
        ],
        triggeringExamples: [
            "guard true else { return }",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "guard[^\n]*return[^\n]\n*"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, byteOffset: $0.location))
        }
    }
}
