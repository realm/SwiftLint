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

    func testTrailingWhitespaceConfigurationThrowsOnBadConfig() {
        let config = "unknown"
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false)
        checkError(ConfigurationError.UnknownConfiguration) {
            try configuration.applyConfiguration(config)
        }
    }

    func testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false)
        XCTAssertFalse(configuration1.ignoresEmptyLines)

        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true)
        XCTAssertTrue(configuration2.ignoresEmptyLines)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false)
        do {
            let config1 = ["ignores_empty_lines": true]
            try configuration.applyConfiguration(config1)
            XCTAssertTrue(configuration.ignoresEmptyLines)

            let config2 = ["ignores_empty_lines": false]
            try configuration.applyConfiguration(config2)
            XCTAssertFalse(configuration.ignoresEmptyLines)
        } catch {
            XCTFail()
        }
    }

    func testTrailingWhitespaceConfigurationCompares() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false)
        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true)
        XCTAssertFalse(configuration1 == configuration2)

        let configuration3 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true)
        XCTAssertTrue(configuration2 == configuration3)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false)
        configuration.severityConfiguration.severity = .Warning

        do {
            try configuration.applyConfiguration(["severity": "error"])
            XCTAssert(configuration.severityConfiguration.severity == .Error)
        } catch {
            XCTFail()
        }
    }

    func testOverridenSuperCallConfigurationFromDictionary() {
        var configuration = OverridenSuperCallConfiguration()
        XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

        let conf1 = [
            "severity": "error",
            "excluded": "viewWillAppear(_:)"
        ]
        do {
            try configuration.applyConfiguration(conf1)
            XCTAssert(configuration.severityConfiguration.severity == .Error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
        } catch {
            XCTFail()
        }

        let conf2 = [
            "severity": "error",
            "excluded": "viewWillAppear(_:)",
            "included": ["*", "testMethod1()", "testMethod2(_:)"]
        ]
        do {
            try configuration.applyConfiguration(conf2)
            XCTAssert(configuration.severityConfiguration.severity == .Error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail()
        }

        let conf3 = [
            "severity": "warning",
            "excluded": "*",
            "included": ["testMethod1()", "testMethod2(_:)"]
        ]
        do {
            try configuration.applyConfiguration(conf3)
            XCTAssert(configuration.severityConfiguration.severity == .Warning)
            XCTAssert(configuration.resolvedMethodNames.count == 2)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail()
        }
    }
}
