//
//  SwitchCaseAlignmentRuleTests.swift
//  SwiftLint
//
//  Created by Shai Mishali on 4/24/18.
//  Copyright © 2018 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class SwitchCaseAlignmentRuleTests: XCTestCase {
    func testSwitchCaseAlignment() {
        verifyRule(SwitchCaseAlignmentRule.description)
    }

    func testSwitchCaseAlignmentWithoutIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description)
    }

    func testSwitchCaseAlignmentWithIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }
}
