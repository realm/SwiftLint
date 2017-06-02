//
//  IdentifierNameRuleTests.swift
//  SwiftLint
//
//  Created by Javier Hernandez on 16/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class IdentifierNameRuleTests: XCTestCase {

    func testIdentifierName() {
        verifyRule(IdentifierNameRule.description)
    }

    func testIdentifierNameWithAllowedSymbols() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "let myLet$ = 0",
            "let myLet% = 0",
            "let myLet$% = 0"
        ]

        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: baseDescription.triggeringExamples,
                                          corrections: baseDescription.corrections,
                                          deprecatedAliases: baseDescription.deprecatedAliases)

        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testIdentifierNameWithIgnoreStartWithLowercase() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamplesToRemove = [
            "↓let MyLet = 0",
            "enum Foo { case ↓MyEnum }"
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.map { $0.replacingOccurrences(of: "↓", with: "") }
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: triggeringExamples,
                                          corrections: baseDescription.corrections,
                                          deprecatedAliases: baseDescription.deprecatedAliases)

        verifyRule(description, ruleConfiguration: ["validates_start_lowercase": false])
    }
}
