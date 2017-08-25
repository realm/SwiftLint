//
//  RuleConfigurationTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

// swiftlint:disable type_body_length

class RuleConfigurationsTests: XCTestCase {
    func testNameConfigurationSetsCorrectly() throws {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": ["id"],
                       "allowed_symbols": ["$"],
                       "validates_start_with_lowercase": false] as [String: Any]
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                           minLengthError: 0,
                                           maxLengthWarning: 0,
                                           maxLengthError: 0)
        let comp = NameConfiguration(minLengthWarning: 17,
                                     minLengthError: 7,
                                     maxLengthWarning: 170,
                                     maxLengthError: 700,
                                     excluded: ["id"],
                                     allowedSymbols: ["$"],
                                     validatesStartWithLowercase: false)

        try nameConfig.apply(configuration: config)
        XCTAssertEqual(nameConfig, comp)
    }

    func testNameConfigurationMinLengthThreshold() {
        var nameConfig = NameConfiguration(minLengthWarning: 7,
                                           minLengthError: 17,
                                           maxLengthWarning: 0,
                                           maxLengthError: 0,
                                           excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 17)

        nameConfig = NameConfiguration(minLengthWarning: 7,
                                       minLengthError: nil,
                                       maxLengthWarning: 0,
                                       maxLengthError: 0,
                                       excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 7)
    }

    func testNameConfigurationMaxLengthThreshold() {
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                           minLengthError: 0,
                                           maxLengthWarning: 17,
                                           maxLengthError: 7,
                                           excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 7)

        nameConfig = NameConfiguration(minLengthWarning: 0,
                                       minLengthError: 0,
                                       maxLengthWarning: 17,
                                       maxLengthError: nil,
                                       excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 17)
    }

    func testNestingConfigurationSetsCorrectly() {
        let config = [
            "type_level": [
                "warning": 7, "error": 17
            ],
            "statement_level": [
                "warning": 8, "error": 18
            ]
        ] as [String: Any]
        var nestingConfig = NestingConfiguration(typeLevelWarning: 0,
                                                 typeLevelError: nil,
                                                 statementLevelWarning: 0,
                                                 statementLevelError: nil)
        do {
            try nestingConfig.apply(configuration: config)
            XCTAssertEqual(nestingConfig.typeLevel.warning, 7)
            XCTAssertEqual(nestingConfig.statementLevel.warning, 8)
            XCTAssertEqual(nestingConfig.typeLevel.error, 17)
            XCTAssertEqual(nestingConfig.statementLevel.error, 18)
        } catch {
            XCTFail("Failed to configure nested configurations")
        }
    }

    func testSeverityConfigurationFromDictionary() {
        let config = ["severity": "warning"]
        let comp = SeverityConfiguration(.warning)
        var severityConfig = SeverityConfiguration(.error)
        do {
            try severityConfig.apply(configuration: config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail("Failed to configure severity from dictionary")
        }
    }

    func testSeverityLevelConfigParams() {
        let severityConfig = SeverityLevelsConfiguration(warning: 17, error: 7)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .error, value: 7),
            RuleParameter(severity: .warning, value: 17)])
    }

    func testSeverityLevelConfigPartialParams() {
        let severityConfig = SeverityLevelsConfiguration(warning: 17, error: nil)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .warning, value: 17)])
    }

    func testSeverityLevelConfigApplyNilErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration(warning: 17, error: 20)
        let error: Int? = nil
        try severityConfig.apply(configuration: ["error": error as Any, "warning": 18])
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .warning, value: 18)])
    }

    func testSeverityLevelConfigApplyMissingErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration(warning: 17, error: 20)
        try severityConfig.apply(configuration: ["warning": 18])
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .error, value: 20),
                                               RuleParameter(severity: .warning, value: 18)])
    }

//    func testRegexConfigurationThrows() {
//        let config = 17
//        var regexConfig = RegexConfiguration(identifier: "")
//        checkError(ConfigurationError.unknownConfiguration) {
//            try regexConfig.apply(configuration: config)
//        }
//    }

//    func testRegexRuleDescription() {
//        var regexConfig = RegexConfiguration(identifier: "regex")
//        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
//                                                                name: "regex",
//                                                                description: "", kind: .style))
//        regexConfig.name = "name"
//        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
//                                                                name: "name",
//                                                                description: "", kind: .style))
//    }

    func testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        XCTAssertFalse(configuration1.ignoresEmptyLines)

        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertTrue(configuration2.ignoresEmptyLines)
    }

    func testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        XCTAssertTrue(configuration1.ignoresComments)

        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: false)
        XCTAssertFalse(configuration2.ignoresComments)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        do {
            let config1 = ["ignores_empty_lines": true]
            try configuration.apply(configuration: config1)
            XCTAssertTrue(configuration.ignoresEmptyLines)

            let config2 = ["ignores_empty_lines": false]
            try configuration.apply(configuration: config2)
            XCTAssertFalse(configuration.ignoresEmptyLines)
        } catch {
            XCTFail("Failed to apply ignores_empty_lines")
        }
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        do {
            let config1 = ["ignores_comments": true]
            try configuration.apply(configuration: config1)
            XCTAssertTrue(configuration.ignoresComments)

            let config2 = ["ignores_comments": false]
            try configuration.apply(configuration: config2)
            XCTAssertFalse(configuration.ignoresComments)
        } catch {
            XCTFail("Failed to apply ignores_comments")
        }
    }

    func testTrailingWhitespaceConfigurationCompares() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertFalse(configuration1 == configuration2)

        let configuration3 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertTrue(configuration2 == configuration3)

        let configuration4 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: false)

        XCTAssertFalse(configuration1 == configuration4)

        let configuration5 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: false)

        XCTAssertFalse(configuration1 == configuration5)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)

        do {
            try configuration.apply(configuration: ["severity": "error"])
            XCTAssert(configuration.severity == .error)
        } catch {
            XCTFail("Failed to apply severity")
        }
    }

    func testOverridenSuperCallConfigurationFromDictionary() {
        var configuration = OverridenSuperCallConfiguration()
        XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

        let conf1: [String: Any] = ["severity": "error", "excluded": ["viewWillAppear(_:)"]]
        do {
            try configuration.apply(configuration: conf1)
            XCTAssert(configuration.severity == .error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf1)")
        }

        let conf2 = [
            "severity": "error",
            "excluded": ["viewWillAppear(_:)"],
            "included": ["*", "testMethod1()", "testMethod2(_:)"]
        ] as [String: Any]
        do {
            try configuration.apply(configuration: conf2)
            XCTAssert(configuration.severity == .error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf2)")
        }

        let conf3 = [
            "severity": "warning",
            "excluded": ["*"],
            "included": ["testMethod1()", "testMethod2(_:)"]
        ] as [String: Any]
        do {
            try configuration.apply(configuration: conf3)
            XCTAssert(configuration.severity == .warning)
            XCTAssert(configuration.resolvedMethodNames.count == 2)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf3)")
        }
    }
}
