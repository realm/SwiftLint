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
        let nonTriggeringExamples = [
            "@objc var x: String",
            "@objc func foo()",
            "@nonobjc\n func foo()",
            "class Foo {\n" +
                "@objc private var object: RLMWeakObjectHandle?\n" +
                "@objc private var property: RLMProperty?\n" +
            "}"
        ]
        let triggeringExamples = [
            "@objc\n ↓var x: String",
            "@objc\n ↓func foo()",
            "@nonobjc ↓func foo()"
        ]

        let alwaysOnSameLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnSameLineDescription,
                   ruleConfiguration: ["always_on_same_line": ["@objc"]])

    }

    func testAttributesWithAlwaysOnLineAbove() {
        // Test with custom `always_on_line_above`
        let nonTriggeringExamples = [
            "@objc\n var x: String",
            "@objc\n func foo()",
            "@nonobjc\n func foo()"
        ]
        let triggeringExamples = [
            "@objc ↓var x: String",
            "@objc ↓func foo()",
            "@nonobjc ↓func foo()"
        ]

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnNewLineDescription,
                   ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }
}
