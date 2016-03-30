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

class RuleConfigurationsTests: XCTestCase {

    func testNameConfigurationSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id"]
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        let comp = NameConfiguration(minLengthWarning: 17,
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

    func testNameConfigurationThrowsOnBadConfig() {
        let config = 17
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        checkError(ConfigurationError.UnknownConfiguration) {
            try nameConfig.applyConfiguration(config)
        }
    }

    func testNameConfigurationMinLengthThreshold() {
        var nameConfig = NameConfiguration(minLengthWarning: 7,
                                    minLengthError: 17,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0,
                                    excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 17)

        nameConfig.minLength.error = nil
        XCTAssertEqual(nameConfig.minLengthThreshold, 7)
    }

    func testNameConfigurationMaxLengthThreshold() {
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 17,
                                    maxLengthError: 7,
                                    excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 7)

        nameConfig.maxLength.error = nil
        XCTAssertEqual(nameConfig.maxLengthThreshold, 17)
    }

    func testSeverityConfigurationFromString() {
        let config = "Warning"
        let comp = SeverityConfiguration(.Warning)
        var severityConfig = SeverityConfiguration(.Error)
        do {
            try severityConfig.applyConfiguration(config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail()
        }
    }

    func testSeverityConfigurationFromDictionary() {
        let config = ["severity": "warning"]
        let comp = SeverityConfiguration(.Warning)
        var severityConfig = SeverityConfiguration(.Error)
        do {
            try severityConfig.applyConfiguration(config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail()
        }
    }

    func testSeverityConfigurationThrowsOnBadConfig() {
        let config = 17
        var severityConfig = SeverityConfiguration(.Warning)
        checkError(ConfigurationError.UnknownConfiguration) {
            try severityConfig.applyConfiguration(config)
        }
    }

    func testSeverityLevelConfigParams() {
        let severityConfig = SeverityLevelsConfiguration(warning: 17, error: 7)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .Error, value: 7),
            RuleParameter(severity: .Warning, value: 17)])
    }

    func testSeverityLevelConfigPartialParams() {
        let severityConfig = SeverityLevelsConfiguration(warning: 17, error: nil)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .Warning, value: 17)])
    }

    func testRegexConfigurationThrows() {
        let config = 17
        var regexConfig = RegexConfiguration(identifier: "")
        checkError(ConfigurationError.UnknownConfiguration) {
            try regexConfig.applyConfiguration(config)
        }
    }

    func testRegexRuleDescription() {
        var regexConfig = RegexConfiguration(identifier: "regex")
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "regex",
                                                                description: ""))
        regexConfig.name = "name"
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "name",
                                                                description: ""))
    }
}
