//
//  ConditionalReturnsOnNewline.swift
//  SwiftLint
//
//  Created by Rohan Dhaimade on 12/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ConditionalReturnsOnNewline: ConfigurationProviderRule, Rule, OptInRule {
    public let configurationDescription = "N/A"
    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        nonTriggeringExamples: [
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}",
            "if true else {\n return true\n}",
            "if true,\n let x = true else {\n return true\n}"
        ],
        triggeringExamples: [
            "guard true else { return }",
            "if true { return }",
            "if true { break } else { return }",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(guard|if)[^\n]*return[^\n]\n*"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, byteOffset: $0.location))
        }
    }
}
