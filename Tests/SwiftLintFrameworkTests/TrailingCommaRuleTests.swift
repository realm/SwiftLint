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

        // Ensure the rule produces the correct reason string.
        let failingCase = "let array = [\n\t1,\n\t2,\n]\n"
        XCTAssertEqual(trailingCommaViolations(failingCase), [
            StyleViolation(
                ruleDescription: TrailingCommaRule.description,
                location: Location(file: nil, line: 3, character: 3),
                reason: "Collection literals should not have trailing commas."
            )]
        )
    }

    private static let triggeringExamples = [
        "let foo = [1, 2,\n 3↓]\n",
        "let foo = [1: 2,\n 2: 3↓]\n",
        "let foo = [1: 2,\n 2: 3↓   ]\n",
        "struct Bar {\n let foo = [1: 2,\n 2: 3↓]\n}\n",
        "let foo = [1, 2,\n 3↓] + [4,\n 5, 6↓]\n",
        "let foo = [\"אבג\", \"αβγ\",\n\"🇺🇸\"↓]\n"
    ]

    private static let corrections: [String: String] = {
        let fixed = triggeringExamples.map { $0.replacingOccurrences(of: "↓", with: ",") }
        var result: [String: String] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()

    private let mandatoryCommaRuleDescription = RuleDescription(
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
        triggeringExamples: TrailingCommaRuleTests.triggeringExamples,
        corrections: TrailingCommaRuleTests.corrections
    )

    func testTrailingCommaRuleWithMandatoryComma() {
        // Verify TrailingCommaRule with test values for when mandatory_comma is true.
        let ruleDescription = mandatoryCommaRuleDescription
        let ruleConfiguration = ["mandatory_comma": true]

        verifyRule(ruleDescription, ruleConfiguration: ruleConfiguration)

        // Ensure the rule produces the correct reason string.
        let failingCase = "let array = [\n\t1,\n\t2\n]\n"
        XCTAssertEqual(trailingCommaViolations(failingCase, ruleConfiguration: ruleConfiguration), [
            StyleViolation(
                ruleDescription: TrailingCommaRule.description,
                location: Location(file: nil, line: 3, character: 3),
                reason: "Multi-line collection literals should have trailing commas."
            )]
        )
    }

    private func trailingCommaViolations(_ string: String, ruleConfiguration: Any? = nil) -> [StyleViolation] {
        let config = makeConfig(ruleConfiguration, TrailingCommaRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
