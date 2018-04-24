//
//  SwitchCaseAlignmentRuleTests.swift
//  SwiftLint
//
//  Created by Shai Mishali on 4/24/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class SwitchCaseAlignmentRuleTests: XCTestCase {
    func testSwitchCaseAlignment() {
        verifyRule(SwitchCaseAlignmentRule.description)
    }

    func testSwitchCaseAlignmentWithoutIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description

        let description = baseDescription.with(nonTriggeringExamples: SwitchCaseAlignmentRule.Examples.nonIndentedCases)
        verifyRule(description)
    }

    func testSwitchCaseAlignmentWithoutIndentedCasesAndViolation() {
        let baseDescription = SwitchCaseAlignmentRule.description

        let description = baseDescription.with(triggeringExamples: SwitchCaseAlignmentRule.Examples.indentedCases)
        verifyRule(description)
    }

    func testSwitchCaseAlignmentWithIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let description = baseDescription.with(nonTriggeringExamples: SwitchCaseAlignmentRule.Examples.indentedCases)

        verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }

    func testSwitchCaseAlignmentWithIndentedCasesAndViolation() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let description = baseDescription.with(nonTriggeringExamples: SwitchCaseAlignmentRule.Examples.nonIndentedCases)

        verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }
}
