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
}
