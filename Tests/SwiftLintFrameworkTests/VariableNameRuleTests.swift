//
//  VariableNameRuleTests.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/18/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class VariableNameRuleTests: XCTestCase {

    func testVariableNameWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(VariableNameRule.description)
    }

    func testVariableNameWithAdditionalAllowedCharacters() {
        // Test with custom `additional_allowed_characters`
        let variableNameDescription = RuleDescription(
            identifier: VariableNameRule.description.identifier,
            name: VariableNameRule.description.name,
            description: VariableNameRule.description.description,
            nonTriggeringExamples: [
                "let m_myLet = 0"
            ],
            triggeringExamples: [
                "↓let 😇😂😎 = 0"
            ]
        )

        verifyRule(variableNameDescription,
                   ruleConfiguration: ["min_length": ["warning": 3, "error": 2],
                                       "max_length": ["warning": 40, "error": 60],
                                       "additional_allowed_characters": "_"])
    }
}

extension VariableNameRuleTests {
    static var allTests: [(String, (VariableNameRuleTests) -> () throws -> Void)] {
        return [
            ("testVariableNameWithDefaultConfiguration", testVariableNameWithDefaultConfiguration),
            ("testVariableNameWithAdditionalAllowedCharacters", testVariableNameWithAdditionalAllowedCharacters)
        ]
    }
}
