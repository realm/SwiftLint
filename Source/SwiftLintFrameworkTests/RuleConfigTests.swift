//
//  RuleConfigurationTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
@testable import SwiftLintFramework
import SourceKittenFramework

class RuleConfigurationurationsTests: XCTestCase {

    // protocol XCTestCaseProvider
    lazy var allTests: [(String, () throws -> Void)] = [
        ("testNameConfigSetsCorrectly", self.testNameConfigSetsCorrectly),
        ("testNameConfigThrowsOnBadConfig", self.testNameConfigThrowsOnBadConfig),
        ("testNameConfigMinLengthThreshold", self.testNameConfigMinLengthThreshold),
        ("testNameConfigMaxLengthThreshold", self.testNameConfigMaxLengthThreshold),
        ("testSeverityConfigFromString", self.testSeverityConfigFromString),
        ("testSeverityConfigFromDictionary", self.testSeverityConfigFromDictionary),
        ("testSeverityConfigThrowsOnBadConfig", self.testSeverityConfigThrowsOnBadConfig),
        ("testSeverityLevelConfigParams", self.testSeverityLevelConfigParams),
        ("testSeverityLevelConfigPartialParams", self.testSeverityLevelConfigPartialParams),
        ("testRegexConfigThrows", self.testRegexConfigThrows),
        ("testRegexRuleDescription", self.testRegexRuleDescription),
    ]

    func testNameConfigSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id"]
        var nameConfig = NameConfig(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        let comp = NameConfig(minLengthWarning: 17,
                              minLengthError: 7,
                              maxLengthWarning: 170,
                              maxLengthError: 700,
                              excluded: ["id"])
        do {
            try nameConfig.applyConfiguration(config)
            XCTAssertEqual(nameConfig, comp)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testNameConfigThrowsOnBadConfig() {
        let config = 17
        var nameConfig = NameConfig(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        checkError(ConfigurationError.UnknownConfiguration) {
            try nameConfig.applyConfiguration(config)
        }
    }

    func testNameConfigMinLengthThreshold() {
        var nameConfig = NameConfig(minLengthWarning: 7,
                                    minLengthError: 17,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0,
                                    excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 17)

        nameConfig.minLength.error = nil
        XCTAssertEqual(nameConfig.minLengthThreshold, 7)
    }

    func testNameConfigMaxLengthThreshold() {
        var nameConfig = NameConfig(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 17,
                                    maxLengthError: 7,
                                    excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 7)

        nameConfig.maxLength.error = nil
        XCTAssertEqual(nameConfig.maxLengthThreshold, 17)
    }

    func testSeverityConfigFromString() {
        let config = "Warning"
        let comp = SeverityConfig(.Warning)
        var severityConfig = SeverityConfig(.Error)
        do {
            try severityConfig.applyConfiguration(config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail()
        }
    }

    func testSeverityConfigFromDictionary() {
        let config = ["severity": "warning"]
        let comp = SeverityConfig(.Warning)
        var severityConfig = SeverityConfig(.Error)
        do {
            try severityConfig.applyConfiguration(config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail()
        }
    }

    func testSeverityConfigThrowsOnBadConfig() {
        let config = 17
        var severityConfig = SeverityConfig(.Warning)
        checkError(ConfigurationError.UnknownConfiguration) {
            try severityConfig.applyConfiguration(config)
        }
    }

    func testSeverityLevelConfigParams() {
        let severityConfig = SeverityLevelsConfig(warning: 17, error: 7)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .Error, value: 7),
            RuleParameter(severity: .Warning, value: 17)])
    }

    func testSeverityLevelConfigPartialParams() {
        let severityConfig = SeverityLevelsConfig(warning: 17, error: nil)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .Warning, value: 17)])
    }

    func testRegexConfigThrows() {
        let config = 17
        var regexConfig = RegexConfig(identifier: "")
        checkError(ConfigurationError.UnknownConfiguration) {
            try regexConfig.applyConfiguration(config)
        }
    }

    func testRegexRuleDescription() {
        var regexConfig = RegexConfig(identifier: "regex")
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "regex",
                                                                description: ""))
        regexConfig.name = "name"
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "name",
                                                                description: ""))
    }
}
