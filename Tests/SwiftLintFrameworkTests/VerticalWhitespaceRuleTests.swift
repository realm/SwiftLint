//
//  VerticalWhitespaceRuleTests.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class VerticalWhitespaceRuleTests: XCTestCase {

    private let ruleID = VerticalWhitespaceRule.description.identifier

    func testVerticalWhitespaceWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(VerticalWhitespaceRule.description)
    }

    func testAttributesWithMaxEmptyLines() {
        // Test with custom `max_empty_lines`
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: ["let aaaa = 0\n\n\n"])
            .with(triggeringExamples: ["struct AAAA {}\n\n\n\n"])
            .with(corrections: [:])

        verifyRule(maxEmptyLinesDescription,
                   ruleConfiguration: ["max_empty_lines": 2])
    }

    func testAutoCorrectionWithMaxEmptyLines() {
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: [])
            .with(triggeringExamples: [])
            .with(corrections: [
                "let b = 0\n\n↓\n↓\n↓\n\nclass AAA {}\n": "let b = 0\n\n\nclass AAA {}\n",
                "let b = 0\n\n\nclass AAA {}\n": "let b = 0\n\n\nclass AAA {}\n"
            ])

        verifyRule(maxEmptyLinesDescription,
                   ruleConfiguration: ["max_empty_lines": 2])
    }

    func testViolationMessageWithMaxEmptyLines() {
        guard let config = makeConfig(["max_empty_lines": 2], ruleID) else {
            XCTFail("Failed to create configuration")
            return
        }
        let allViolations = violations("let aaaa = 0\n\n\n\nlet bbb = 2\n", config: config)

        let verticalWhiteSpaceViolation = allViolations.first { $0.ruleDescription.identifier == ruleID }
        if let violation = verticalWhiteSpaceViolation {
            XCTAssertEqual(violation.reason, "Limit vertical whitespace to maximum 2 empty lines. Currently 3.")
        } else {
            XCTFail("A vertical whitespace violation should have been triggered!")
        }
    }

    func testViolationMessageWithDefaultConfiguration() {
        let allViolations = violations("let aaaa = 0\n\n\n\nlet bbb = 2\n")
        let verticalWhiteSpaceViolation = allViolations.first(where: { $0.ruleDescription.identifier == ruleID })
        if let violation = verticalWhiteSpaceViolation {
            XCTAssertEqual(violation.reason, "Limit vertical whitespace to a single empty line. Currently 3.")
        } else {
            XCTFail("A vertical whitespace violation should have been triggered!")
        }
    }
}
