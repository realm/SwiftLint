//
//  RuleTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

struct RuleWithLevelsMock: ConfigurationProviderRule {
    var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)

    static let description = RuleDescription(identifier: "severity_level_mock",
                                             name: "",
                                             description: "",
                                             kind: .style,
                                             deprecatedAliases: ["mock"])

    func validate(file: File) -> [StyleViolation] { return [] }
}

class RuleTests: XCTestCase {

    fileprivate struct RuleMock1: Rule {
        var configurationDescription: String { return "N/A" }
        static let description = RuleDescription(identifier: "RuleMock1", name: "",
                                                 description: "", kind: .style)

        init() {}
        init(configuration: [String: Any]) throws { self.init() }

        func validate(file: File) -> [StyleViolation] {
            return []
        }
    }

    fileprivate struct RuleMock2: Rule {
        var configurationDescription: String { return "N/A" }
        static let description = RuleDescription(identifier: "RuleMock2", name: "",
                                                 description: "", kind: .style)

        init() {}
        init(configuration: [String: Any]) throws { self.init() }

        func validate(file: File) -> [StyleViolation] {
            return []
        }
    }

    fileprivate struct RuleWithLevelsMock2: ConfigurationProviderRule {
        var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)
        static let description = RuleDescription(identifier: "violation_level_mock2",
                                                 name: "",
                                                 description: "", kind: .style)

        func validate(file: File) -> [StyleViolation] { return [] }
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

    func testSeverityLevelRuleInitsWithConfigDictionary() throws {
        let config = ["warning": 17, "error": 7]
        let rule = try RuleWithLevelsMock(configuration: config)

        XCTAssertEqual(rule.configuration.warning, 17)
        XCTAssertEqual(rule.configuration.error, 7)
    }

    func testSeverityLevelRuleInitsWithWarningOnlyConfigDictionary() throws {
        let config = ["warning": 17]
        let rule = try RuleWithLevelsMock(configuration: config)

        XCTAssertEqual(rule.configuration.warning, 17)
        XCTAssertEqual(rule.configuration.error, rule.configuration.errorParameter.default)
    }

    func testSeverityLevelRuleInitsWithErrorOnlyConfigDictionary() throws {
        let config = ["error": 17]
        let rule = try RuleWithLevelsMock(configuration: config)

        XCTAssertEqual(rule.configuration.warning, rule.configuration.warningParameter.default)
        XCTAssertEqual(rule.configuration.error, 17)
    }

    func testSeverityLevelRuleNotEqual() throws {
        let config = ["warning": 17]
        let rule = try RuleWithLevelsMock(configuration: config)
        XCTAssertEqual(rule.isEqualTo(RuleWithLevelsMock()), false)
    }

    func testDifferentSeverityLevelRulesNotEqual() {
        XCTAssertFalse(RuleWithLevelsMock().isEqualTo(RuleWithLevelsMock2()))
    }
}
