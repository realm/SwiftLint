//
//  RuleTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import XCTest
import SourceKittenFramework
@testable import SwiftLintFramework

class RuleTests: XCTestCase {

    private class RuleMock1: Rule {
        static let description = RuleDescription(identifier: "RuleMock1", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private class RuleMock2: Rule {
        static let description = RuleDescription(identifier: "RuleMock2", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private class ParameterizedRuleMock1: RuleMock1, ParameterizedRule {
        let parameters: [RuleParameter<Int>]
        required init(parameters: [RuleParameter<Int>]) {
            self.parameters = parameters
        }
    }

    private class ParameterizedRuleMock2: RuleMock2, ParameterizedRule {
        let parameters: [RuleParameter<Int>]
        required init(parameters: [RuleParameter<Int>]) {
            self.parameters = parameters
        }
    }

    func testRuleIsEqualTo() {
        XCTAssertTrue(RuleMock1().isEqualTo(RuleMock1()))
    }

    func testRuleIsNotEqualTo() {
        XCTAssertFalse(RuleMock1().isEqualTo(RuleMock2()))
    }

    func testParameterizedRuleIsEqualTo() {
        let params = [RuleParameter(severity: .Warning, value: 20),
                      RuleParameter(severity: .Warning, value: 40)]
        XCTAssertTrue(ParameterizedRuleMock1(parameters: params)
           .isEqualTo(ParameterizedRuleMock1(parameters: params)))
    }

    func testParameterizedRuleIsNotEqualTo1() {
        let params1 = [RuleParameter(severity: .Warning, value: 20),
                       RuleParameter(severity: .Warning, value: 40)]
        let params2 = [RuleParameter(severity: .Warning, value: 40),
                       RuleParameter(severity: .Warning, value: 60)]
        XCTAssertFalse(ParameterizedRuleMock1(parameters: params1)
            .isEqualTo(ParameterizedRuleMock1(parameters: params2)))
    }

    func testParameterizedRuleIsNotEqualTo2() {
        let params1 = [RuleParameter(severity: .Warning, value: 20),
            RuleParameter(severity: .Warning, value: 40)]
        let params2 = [RuleParameter(severity: .Warning, value: 40),
            RuleParameter(severity: .Warning, value: 60)]
        XCTAssertFalse(ParameterizedRuleMock1(parameters: params1)
            .isEqualTo(ParameterizedRuleMock2(parameters: params2)))
    }

    func testParameterizedRuleIsNotEqualToRule() {
        let params = [RuleParameter(severity: .Warning, value: 20),
            RuleParameter(severity: .Warning, value: 40)]
        XCTAssertFalse(ParameterizedRuleMock1(parameters: params)
            .isEqualTo(RuleMock2()))
    }

    func testRuleArraysWithDifferentCountsNotEqual() {
        XCTAssertNotEqual([RuleMock1(), RuleMock2()], [RuleMock1()])
    }

}
