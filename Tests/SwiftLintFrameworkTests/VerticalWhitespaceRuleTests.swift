//
//  VerticalWhitespaceRuleTests.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
@testable import SourceKittenFramework
import XCTest

class VerticalWhitespaceRuleTests: XCTestCase {
    
    private let ruleID = "vertical_whitespace"

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
    
    func testViolationMessageWithMaxEmptyLines() {
        guard let config = makeConfig(["max_empty_lines": 2], ruleID) else {
            XCTFail("Failed to create configuration")
            return
        }
        let allViolations = violations("let aaaa = 0\n\n\n\nlet bbb = 2\n", config: config)
        let verticalWhiteSpaceViolation = allViolations.filter { $0.ruleDescription.identifier == ruleID }.first
        if let violation = verticalWhiteSpaceViolation {
            XCTAssertEqual(violation.reason, "Limit vertical whitespace to maximum 2 empty lines. Currently 3.")
        }
    }
    
    func testVilationMessageWithDefaultConfiguration() {
        let allViolations = violations("let aaaa = 0\n\n\n\nlet bbb = 2\n")
        let verticalWhiteSpaceViolation = allViolations.filter { $0.ruleDescription.identifier == ruleID }.first
        if let violation = verticalWhiteSpaceViolation {
            XCTAssertEqual(violation.reason, "Limit vertical whitespace to a single empty line. Currently 3.")
        }
    }
}
