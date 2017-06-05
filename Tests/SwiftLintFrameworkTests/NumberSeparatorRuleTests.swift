//
//  NumberSeparatorRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class NumberSeparatorRuleTests: XCTestCase {

    func testNumberSeparatorWithDefaultConfiguration() {
        verifyRule(NumberSeparatorRule.description)
    }

    func testNumberSeparatorWithMinimumLength() {
        let description = RuleDescription(
            identifier: NumberSeparatorRule.description.identifier,
            name: NumberSeparatorRule.description.name,
            description: NumberSeparatorRule.description.description,
            nonTriggeringExamples: [
                "let foo = 10_000",
                "let foo = 1000",
                "let foo = 1000.0001",
                "let foo = 10_000.0001",
                "let foo = 1000.000_01"
            ],
            triggeringExamples: [
                "let foo = ↓1_000",
                "let foo = ↓1.000_1",
                "let foo = ↓1_000.000_1"
            ],
            corrections: [
                "let foo = ↓1_000": "let foo = 1000",
                "let foo = ↓1.000_1": "let foo = 1.0001",
                "let foo = ↓1_000.000_1": "let foo = 1000.0001"
            ]
        )

        verifyRule(description, ruleConfiguration: ["minimum_length": 5])
    }

    func testNumberSeparatorWithMinimumFractionLength() {
        let description = RuleDescription(
            identifier: NumberSeparatorRule.description.identifier,
            name: NumberSeparatorRule.description.name,
            description: NumberSeparatorRule.description.description,
            nonTriggeringExamples: [
                "let foo = 1_000.000_000_1",
                "let foo = 1.000_001",
                "let foo = 100.0001",
                "let foo = 1_000.000_01"
            ],
            triggeringExamples: [
                "let foo = ↓1000",
                "let foo = ↓1.000_1",
                "let foo = ↓1_000.000_1"
            ],
            corrections: [
                "let foo = ↓1000": "let foo = 1_000",
                "let foo = ↓1.000_1": "let foo = 1.0001",
                "let foo = ↓1_000.000_1": "let foo = 1_000.0001"
            ]
        )

        verifyRule(description, ruleConfiguration: ["minimum_fraction_length": 5])
    }
}
