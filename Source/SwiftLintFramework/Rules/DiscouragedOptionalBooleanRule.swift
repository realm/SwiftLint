//
//  DiscouragedOptionalBoolean.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/21/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DiscouragedOptionalBooleanRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_optional_boolean",
        name: "Discouraged Optional Boolean",
        description: "Prefer boolean over optional boolean.",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalBooleanRuleExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalBooleanRuleExamples.triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "Bool\\?"
        let excludingKinds = SyntaxKind.commentAndStringKinds

        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
