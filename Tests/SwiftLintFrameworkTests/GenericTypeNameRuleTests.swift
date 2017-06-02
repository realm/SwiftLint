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

        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: baseDescription.triggeringExamples,
                                          corrections: baseDescription.corrections,
                                          deprecatedAliases: baseDescription.deprecatedAliases)

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
