//
//  TrailingCommaRuleTests.swift
//  SwiftLint
//
//  Created by Matt Rubin on 12/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class TrailingCommaRuleTests: XCTestCase {

    func testTrailingCommaRuleWithDefaultConfiguration() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is false (default).
        verifyRule(TrailingCommaRule.description)
    }

    func testTrailingCommaRuleWithMandatoryComma() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is true.
        let ruleDescription = RuleDescription(
            identifier: TrailingCommaRule.description.identifier,
            name: TrailingCommaRule.description.name,
            description: TrailingCommaRule.description.description,
            nonTriggeringExamples: [
                "let foo = []\n",
                "let foo = [:]\n",
                "let foo = [1, 2, 3,]\n",
                "let foo = [1, 2, 3, ]\n",
                "let foo = [1, 2, 3   ,]\n",
                "let foo = [1: 2, 2: 3, ]\n",
                "struct Bar {\n let foo = [1: 2, 2: 3,]\n}\n",
                "let foo = [Void]()\n",
                "let foo = [(Void, Void)]()\n",
                "let foo = [1, 2, 3]\n",
                "let foo = [1: 2, 2: 3]\n",
                "let foo = [1: 2, 2: 3   ]\n",
                "struct Bar {\n let foo = [1: 2, 2: 3]\n}\n",
                "let foo = [1, 2, 3] + [4, 5, 6]\n"
            ],
            triggeringExamples: [
                "let foo = [1, 2,\n 3↓]\n",
                "let foo = [1: 2,\n 2: 3↓]\n",
                "let foo = [1: 2,\n 2: 3↓   ]\n",
                "struct Bar {\n let foo = [1: 2,\n 2: 3↓]\n}\n",
                "let foo = [1, 2,\n 3↓] + [4,\n 5, 6↓]\n"
            ]
        )

        verifyRule(ruleDescription, ruleConfiguration: ["mandatory_comma": true])
    }
}

extension TrailingCommaRuleTests {
    static var allTests: [(String, (TrailingCommaRuleTests) -> () throws -> Void)] {
        return [
            ("testTrailingCommaRuleWithDefaultConfiguration", testTrailingCommaRuleWithDefaultConfiguration),
            ("testTrailingCommaRuleWithMandatoryComma", testTrailingCommaRuleWithMandatoryComma)
        ]
    }
}
