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
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "let MyLet = 0",
            "enum Foo { case MyEnum }"
        ]
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !$0.contains("MyLet") && !$0.contains("MyEnum") }

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

extension IdentifierNameRuleTests {
    static var allTests: [(String, (IdentifierNameRuleTests) -> () throws -> Void)] {
        return [
            ("testIdentifierName", testIdentifierName),
            ("testIdentifierNameWithAllowedSymbols", testIdentifierNameWithAllowedSymbols),
            ("testIdentifierNameWithIgnoreStartWithLowercase", testIdentifierNameWithIgnoreStartWithLowercase)
        ]
    }
}
