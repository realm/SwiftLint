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

struct RuleWithLevelsMock: ConfigProviderRule {
    var config = SeverityLevelsConfig(warning: 2, error: 3)

    static let description = RuleDescription(identifier: "severity_level_mock",
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

    private struct RuleWithLevelsMock2: ConfigProviderRule {
        var config = SeverityLevelsConfig(warning: 2, error: 3)

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

    func testSeverityLevelRuleInitsWithConfigDictionary() {
        let config = ["warning": 17, "error": 7]
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.warning = 17
        comp.config.error = 7
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithWarningOnlyConfigDictionary() {
        let config = ["warning": 17]
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.warning = 17
        comp.config.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithErrorOnlyConfigDictionary() {
        let config = ["error": 17]
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.error = 17
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithConfigArray() {
        let config = [17, 7] as AnyObject
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.warning = 17
        comp.config.error = 7
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithSingleValueConfigArray() {
        let config = [17] as AnyObject
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.warning = 17
        comp.config.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithLiteral() {
        let config = 17 as AnyObject
        let rule = try? RuleWithLevelsMock(config: config)
        var comp = RuleWithLevelsMock()
        comp.config.warning = 17
        comp.config.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleNotEqual() {
        let config = 17 as AnyObject
        let rule = try? RuleWithLevelsMock(config: config)
        XCTAssertEqual(rule?.isEqualTo(RuleWithLevelsMock()), false)
    }

    func testDifferentSeverityLevelRulesNotEqual() {
        XCTAssertFalse(RuleWithLevelsMock().isEqualTo(RuleWithLevelsMock2()))
    }
}
