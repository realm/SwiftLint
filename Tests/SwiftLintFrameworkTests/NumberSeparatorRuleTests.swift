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
        let nonTriggeringExamples = [
            "let foo = 10_000",
            "let foo = 1000",
            "let foo = 1000.0001",
            "let foo = 10_000.0001",
            "let foo = 1000.000_01"
        ]
        let triggeringExamples = [
            "let foo = ↓1_000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1"
        ]
        let corrections = [
            "let foo = ↓1_000": "let foo = 1000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1000.0001"
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_length": 5])
    }

    func testNumberSeparatorWithMinimumFractionLength() {
        let nonTriggeringExamples = [
            "let foo = 1_000.000_000_1",
            "let foo = 1.000_001",
            "let foo = 100.0001",
            "let foo = 1_000.000_01"
        ]
        let triggeringExamples = [
            "let foo = ↓1000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1"
        ]
        let corrections = [
            "let foo = ↓1000": "let foo = 1_000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1_000.0001"
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_fraction_length": 5])
    }
}
