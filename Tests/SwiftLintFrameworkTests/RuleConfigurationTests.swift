//
//  RuleConfigurationTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework
import XCTest
@testable import SwiftLintFramework

// swiftlint:disable type_body_length
// swiftlint:disable file_length

class RuleConfigurationsTests: XCTestCase {
    func testNameConfigurationSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id"] as [String: Any]
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
            try nameConfig.apply(configuration: config)
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
        checkError(ConfigurationError.unknownConfiguration) {
            try nameConfig.apply(configuration: config)
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
            XCTFail()
        }
    }

    func testNestingConfigurationThrowsOnBadConfig() {
        let config = 17
        var nestingConfig = NestingConfiguration(typeLevelWarning: 0,
                                                 typeLevelError: nil,
                                                 statementLevelWarning: 0,
                                                 statementLevelError: nil)
        checkError(ConfigurationError.unknownConfiguration) {
            try nestingConfig.apply(configuration: config)
        }
    }

    func testSeverityConfigurationFromString() {
        let config = "Warning"
        let comp = SeverityConfiguration(.warning)
        var severityConfig = SeverityConfiguration(.error)
        do {
            try severityConfig.apply(configuration: config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail()
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
            XCTFail()
        }
    }

    func testSeverityConfigurationThrowsOnBadConfig() {
        let config = 17
        var severityConfig = SeverityConfiguration(.warning)
        checkError(ConfigurationError.unknownConfiguration) {
            try severityConfig.apply(configuration: config)
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

    func testRegexConfigurationThrows() {
        let config = 17
        var regexConfig = RegexConfiguration(identifier: "")
        checkError(ConfigurationError.unknownConfiguration) {
            try regexConfig.apply(configuration: config)
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
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: config)
        }
    }

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
            XCTFail()
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
            XCTFail()
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
        configuration.severityConfiguration.severity = .warning

        do {
            try configuration.apply(configuration: ["severity": "error"])
            XCTAssert(configuration.severityConfiguration.severity == .error)
        } catch {
            XCTFail()
        }
    }

    func testOverridenSuperCallConfigurationFromDictionary() {
        var configuration = OverridenSuperCallConfiguration()
        XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

        let conf1 = ["severity": "error", "excluded": "viewWillAppear(_:)"]
        do {
            try configuration.apply(configuration: conf1)
            XCTAssert(configuration.severityConfiguration.severity == .error)
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
        ] as [String: Any]
        do {
            try configuration.apply(configuration: conf2)
            XCTAssert(configuration.severityConfiguration.severity == .error)
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
        ] as [String: Any]
        do {
            try configuration.apply(configuration: conf3)
            XCTAssert(configuration.severityConfiguration.severity == .warning)
            XCTAssert(configuration.resolvedMethodNames.count == 2)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail()
        }
    }
}

// MARK: - ImportsConfiguration tests

extension RuleConfigurationsTests {

    func testSortedImportsConfigurationSetsCorrectly() {
        var data: [String: Any] = ["ignore_case": true]

        var config1 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)
        var config2 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .bottom)

        do {
            try config1.apply(configuration: data)
            XCTAssertEqual(config1, config2)
        } catch {
            XCTFail("Did not configure correctly")
        }

        config1 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .top)
        config2 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .bottom)

        do {
            try config1.apply(configuration: data)
            XCTAssertEqual(config1, config2)
        } catch {
            XCTFail("Did not configure correctly")
        }

        config1 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .top)
        config2 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)

        data = ["ignore_case": false, "testable_imports_position": TestableImportsPosition.bottom]
        do {
            try config1.apply(configuration: data)
            XCTAssertEqual(config1, config2)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testSortedImportsConfigurationThrowsOnBadConfig() {
        var config1 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)
        checkError(ConfigurationError.unknownConfiguration) {
            try config1.apply(configuration: [true, "top"])
        }
    }

    func testSortedImportsConfigurationIgnoreCase() {
        let config1 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .bottom)
        XCTAssertEqual(config1.ignoreCase, true)

        let config2 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)
        XCTAssertEqual(config2.ignoreCase, false)

        var config3 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)
        do {
            try config3.apply(configuration: ["ignore_case": true])
            XCTAssertEqual(config3.ignoreCase, true)
        } catch {
            XCTFail("Did not configure correctly")
        }

        var config4 = SortedImportsConfiguration(ignoreCase: false, testableImportsPosition: .bottom)
        do {
            try config4.apply(configuration: ["ignore_case": false])
            XCTAssertEqual(config4.ignoreCase, false)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testSortedImportsConfigurationTestableImportsPosition() {
        let config1 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .bottom)
        XCTAssertEqual(config1.testableImportsPosition, TestableImportsPosition.bottom)

        let config2 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .top)
        XCTAssertEqual(config2.testableImportsPosition, TestableImportsPosition.top)

        var config3 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .bottom)
        do {
            try config3.apply(configuration: ["testable_imports_position": TestableImportsPosition.top.rawValue])
            XCTAssertEqual(config3.testableImportsPosition, TestableImportsPosition.top)
        } catch {
            XCTFail("Did not configure correctly")
        }

        var config4 = SortedImportsConfiguration(ignoreCase: true, testableImportsPosition: .ignore)
        do {
            try config4.apply(configuration: ["testable_imports_position": TestableImportsPosition.bottom.rawValue])
            XCTAssertEqual(config4.testableImportsPosition, TestableImportsPosition.bottom)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testSortedImportsConfigurationEquality() {
        let possibleTests: [(Bool, TestableImportsPosition)] = [
            (false, .bottom),
            (false, .ignore),
            (false, .top),
            (true, .bottom),
            (true, .ignore),
            (true, .top)
        ]

        possibleTests.enumerated().forEach { index, data in
            let config1 = SortedImportsConfiguration(ignoreCase: data.0, testableImportsPosition: data.1)
            let config2 = SortedImportsConfiguration(ignoreCase: data.0, testableImportsPosition: data.1)
            XCTAssertEqual(config1, config2, "Failed imports configuration equality test data #\(index)")
        }
    }

}

extension RuleConfigurationsTests {
    static var allTests: [(String, (RuleConfigurationsTests) -> () throws -> Void)] {
        return [
            ("testNameConfigurationSetsCorrectly",
                testNameConfigurationSetsCorrectly),
            ("testNameConfigurationThrowsOnBadConfig",
                testNameConfigurationThrowsOnBadConfig),
            ("testNameConfigurationMinLengthThreshold",
                testNameConfigurationMinLengthThreshold),
            ("testNameConfigurationMaxLengthThreshold",
                testNameConfigurationMaxLengthThreshold),
            ("testNestingConfigurationSetsCorrectly",
                testNestingConfigurationSetsCorrectly),
            ("testNestingConfigurationThrowsOnBadConfig",
                testNestingConfigurationThrowsOnBadConfig),
            ("testSeverityConfigurationFromString",
                testSeverityConfigurationFromString),
            ("testSeverityConfigurationFromDictionary",
                testSeverityConfigurationFromDictionary),
            ("testSeverityConfigurationThrowsOnBadConfig",
                testSeverityConfigurationThrowsOnBadConfig),
            ("testSeverityLevelConfigParams",
                testSeverityLevelConfigParams),
            ("testSeverityLevelConfigPartialParams",
                testSeverityLevelConfigPartialParams),
            ("testSortedImportsConfigurationSetsCorrectly",
                testSortedImportsConfigurationSetsCorrectly),
            ("testSortedImportsConfigurationThrowsOnBadConfig",
                testSortedImportsConfigurationThrowsOnBadConfig),
            ("testSortedImportsConfigurationIgnoreCase",
                testSortedImportsConfigurationIgnoreCase),
            ("testSortedImportsConfigurationTestableImportsPosition",
             testSortedImportsConfigurationTestableImportsPosition),
            ("testTrailingWhitespaceConfigurationThrowsOnBadConfig",
                testTrailingWhitespaceConfigurationThrowsOnBadConfig),
            ("testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines",
                testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines),
            ("testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments",
                testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments),
            ("testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines",
                testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines),
            ("testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments",
                testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments),
            ("testTrailingWhitespaceConfigurationCompares",
                testTrailingWhitespaceConfigurationCompares),
            ("testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration",
                testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration),
            ("testOverridenSuperCallConfigurationFromDictionary",
                testOverridenSuperCallConfigurationFromDictionary)
        ]
    }
}
