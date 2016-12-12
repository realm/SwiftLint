//
//  EmptyParametersRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 11/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct EmptyParametersRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parameters",
        name: "Empty Parameters",
        description: "Prefer `() -> ` over `Void -> `.",
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "func foo(completion: () -> Void)\n",
            "func foo(completion: () thows -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: ↓Void -> Void = {}\n",
            "func foo(completion: ↓Void -> Void)\n",
            "func foo(completion: ↓Void throws -> Void)\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let kinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern("Void\\s*(throws\\s+)?->", excludingSyntaxKinds: kinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
