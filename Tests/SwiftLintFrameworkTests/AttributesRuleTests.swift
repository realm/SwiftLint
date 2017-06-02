//
//  AttributesRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 11/30/16.
//  Copyright © 2016 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class AttributesRuleTests: XCTestCase {

    func testAttributesWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(AttributesRule.description)
    }

    func testAttributesWithAlwaysOnSameLine() {
        // Test with custom `always_on_same_line`
        let alwaysOnSameLineDescription = RuleDescription(
            identifier: AttributesRule.description.identifier,
            name: AttributesRule.description.name,
            description: AttributesRule.description.description,
            nonTriggeringExamples: [
                "@objc var x: String",
                "@objc func foo()",
                "@nonobjc\n func foo()",
                "class Foo {\n" +
                    "@objc private var object: RLMWeakObjectHandle?\n" +
                    "@objc private var property: RLMProperty?\n" +
                "}"
            ],
            triggeringExamples: [
                "@objc\n ↓var x: String",
                "@objc\n ↓func foo()",
                "@nonobjc ↓func foo()"
            ]
        )

        verifyRule(alwaysOnSameLineDescription,
                   ruleConfiguration: ["always_on_same_line": ["@objc"]])

    }

    func testAttributesWithAlwaysOnLineAbove() {
        // Test with custom `always_on_line_above`
        let alwaysOnNewLineDescription = RuleDescription(
            identifier: AttributesRule.description.identifier,
            name: AttributesRule.description.name,
            description: AttributesRule.description.description,
            nonTriggeringExamples: [
                "@objc\n var x: String",
                "@objc\n func foo()",
                "@nonobjc\n func foo()"
            ],
            triggeringExamples: [
                "@objc ↓var x: String",
                "@objc ↓func foo()",
                "@nonobjc ↓func foo()"
            ]
        )

        verifyRule(alwaysOnNewLineDescription,
                   ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }
}
