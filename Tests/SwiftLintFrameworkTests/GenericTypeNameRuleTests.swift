//
//  GenericTypeNameRuleTests.swift
//  SwiftLint
//
//  Created by Javier Hernandez on 30/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class GenericTypeNameRuleTests: XCTestCase {

    func testGenericTypeName() {
        verifyRule(GenericTypeNameRule.description)
    }

    func testGenericTypeNameWithAllowedSymbols() {
        let baseDescription = GenericTypeNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "func foo<T$>() {}\n",
            "func foo<T$, U%>(param: U%) -> T$ {}\n",
            "typealias StringDictionary<T$> = Dictionary<String, T$>\n",
            "class Foo<T$%> {}\n",
            "struct Foo<T$%> {}\n",
            "enum Foo<T$%> {}\n"
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithAllowedSymbolsAndViolation() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamples = [
            "func foo<↓T_$>() {}\n"
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    func testGenericTypeNameWithIgnoreStartWithLowercase() {
        let baseDescription = GenericTypeNameRule.description
        let triggeringExamplesToRemove = [
            "func foo<↓type>() {}\n",
            "class Foo<↓type> {}\n",
            "struct Foo<↓type> {}\n",
            "enum Foo<↓type> {}\n"
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.map { $0.replacingOccurrences(of: "↓", with: "") }
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": false])
    }
}
