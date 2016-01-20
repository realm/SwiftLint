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

struct ViolationLevelRuleMock: ViolationLevelRule {
    var warning = RuleParameter(severity: .Warning, value: 2)
    var error = RuleParameter(severity: .Error, value: 3)

    static let description = RuleDescription(identifier: "violation_level_mock",
        name: "",
        description: "")
    func validateFile(file: File) -> [StyleViolation] { return [] }
}

class RuleTests: XCTestCase {

    private struct RuleMock1: Rule {
        init() {}
        static let description = RuleDescription(identifier: "RuleMock1", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private struct RuleMock2: Rule {
        init() {}
        static let description = RuleDescription(identifier: "RuleMock2", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private struct ViolationLevelRuleMock2: ViolationLevelRule {
        var warning = RuleParameter(severity: .Warning, value: 2)
        var error = RuleParameter(severity: .Error, value: 3)

        static let description = RuleDescription(identifier: "violation_level_mock2",
            name: "",
            description: "")
        func validateFile(file: File) -> [StyleViolation] { return [] }
    }

    func testRuleIsEqualTo() {
        XCTAssertTrue(RuleMock1().isEqualTo(RuleMock1()))
    }

    func testRuleIsNotEqualTo() {
        XCTAssertFalse(RuleMock1().isEqualTo(RuleMock2()))
    }

    func testRuleArraysWithDifferentCountsNotEqual() {
        XCTAssertFalse([RuleMock1(), RuleMock2()] == [RuleMock1()])
    }

    func testViolationLevelRuleInitsWithConfigDictionary() {
        let config = ["warning": 17, "error": 7]
        let rule = try? ViolationLevelRuleMock(config: config)
        var comp = ViolationLevelRuleMock()
        comp.warning = RuleParameter(severity: .Warning, value: 17)
        comp.error = RuleParameter(severity: .Error, value: 7)
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testViolationLevelRuleInitsWithConfigArray() {
        let config = [17, 7] as AnyObject
        let rule = try? ViolationLevelRuleMock(config: config)
        var comp = ViolationLevelRuleMock()
        comp.warning = RuleParameter(severity: .Warning, value: 17)
        comp.error = RuleParameter(severity: .Error, value: 7)
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testViolationLevelRuleInitsWithLiteral() {
        let config = 17 as AnyObject
        let rule = try? ViolationLevelRuleMock(config: config)
        var comp = ViolationLevelRuleMock()
        comp.warning = RuleParameter(severity: .Warning, value: 17)
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testViolationLevelRuleNotEqual() {
        let config = 17 as AnyObject
        let rule = try? ViolationLevelRuleMock(config: config)
        XCTAssertEqual(rule?.isEqualTo(ViolationLevelRuleMock()), false)
    }

    func testDifferentViolationLevelRulesNotEqual() {
        XCTAssertFalse(ViolationLevelRuleMock().isEqualTo(ViolationLevelRuleMock2()))
    }
}
