//
//  AttributesRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 30/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class AttributesRuleTests: XCTestCase {

    func testAttributesWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(AttributesRule.description)
    }

    func testAttributesWithAlwaysOnSameLine() {
        // Test with custom `always_on_same_line`
        let alwaysOnSameLineDescription = RuleDescription(
            identifier: "attributes_rule",
            name: "Attributes",
            description: "Attributes should be on their own lines in functions and types, " +
            "but on the same line as variables and imports",
            nonTriggeringExamples: [
                "@objc var x: String",
                "@objc func foo()",
                "@nonobjc\n func foo()"
            ],
            triggeringExamples: [
                "@objc\n var x: String",
                "@objc\n func foo()",
                "@nonobjc func foo()"
            ]
        )

        verifyRule(alwaysOnSameLineDescription,
                   ruleConfiguration: ["always_on_same_line": ["@objc"]])

    }

    func testAttributesWithAlwaysOnLineAbove() {
        // Test with custom `always_on_line_above`
        let alwaysOnNewLineDescription = RuleDescription(
            identifier: "attributes_rule",
            name: "Attributes",
            description: "Attributes should be on their own lines in functions and types, " +
            "but on the same line as variables and imports",
            nonTriggeringExamples: [
                "@objc\n var x: String",
                "@objc\n func foo()",
                "@nonobjc\n func foo()"
            ],
            triggeringExamples: [
                "@objc var x: String",
                "@objc func foo()",
                "@nonobjc func foo()"
            ]
        )

        verifyRule(alwaysOnNewLineDescription,
                   ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }
}
