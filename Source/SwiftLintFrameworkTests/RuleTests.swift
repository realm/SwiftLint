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
        required init() {}
        static let description = RuleDescription(identifier: "RuleMock1", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private class RuleMock2: Rule {
        required init() {}
        static let description = RuleDescription(identifier: "RuleMock2", name: "", description: "")
        func validateFile(file: File) -> [StyleViolation] {
            return []
        }
    }

    private class ParameterizedRuleMock1: RuleMock1, ParameterizedRule {
        required init() {
            parameters = []
        }
        let parameters: [RuleParameter<Int>]
        required init(parameters: [RuleParameter<Int>]) {
            self.parameters = parameters
        }
    }

    private class ParameterizedRuleMock2: RuleMock2, ParameterizedRule {
        required init() {
            parameters = []
        }
        let parameters: [RuleParameter<Int>]
        required init(parameters: [RuleParameter<Int>]) {
            self.parameters = parameters
        }
    }

    final private class ConfigurableRuleMock1: RuleMock1, ParameterizedRule, ConfigurableRule {
        required init() {
            parameters = []
        }
        let parameters: [RuleParameter<Int>]
        required init(parameters: [RuleParameter<Int>]) {
            self.parameters = parameters
        }
    }

    final private class ConfigurableRuleMock2: RuleMock2, ParameterizedRule, ConfigurableRule {
        required init() {
            parameters = []
        }
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

    func testParameterizedConfigurableRuleInits() {
        let config = [1, 2]
        let rule = ConfigurableRuleMock1.init(config: config)
        XCTAssertEqual(rule!.parameters, RuleParameter<Int>.ruleParametersFromArray([1, 2]))
    }

    func testParameterizedConfigurableRuleDoesntInit() {
        let config = ["a", "b"]
        XCTAssertNil(ConfigurableRuleMock1.init(config: config))
    }

    func testParameterizedConfigurableRuleEqual() {
        let config1 = [1, 2]
        let config2 = [1, 2]
        XCTAssertTrue(ConfigurableRuleMock1.init(config: config1)!
           .isEqualTo(ConfigurableRuleMock1.init(config: config2)!))
    }

    func testParameterizedConfigurableRuleNotEqual() {
        let config1 = [1, 2]
        let config2 = [3, 4]
        XCTAssertFalse(ConfigurableRuleMock1.init(config: config1)!
            .isEqualTo(ConfigurableRuleMock1.init(config: config2)!))
    }

    func testDifferentParameterizedConfigurableRulesNotEqual() {
        let config1 = [1, 2]
        let config2 = [1, 2]
        XCTAssertFalse(ConfigurableRuleMock1.init(config: config1)!
            .isEqualTo(ConfigurableRuleMock2.init(config: config2)!))
    }

}
