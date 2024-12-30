@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class LineLengthConfigurationTests: SwiftLintTestCase {
    private let severityLevels = SeverityLevelsConfiguration<LineLengthRule>(warning: 100, error: 150)

    func testLineLengthConfigurationInitializerSetsLength() {
        let configuration1 = LineLengthConfiguration(length: severityLevels)
        XCTAssertEqual(configuration1.length, severityLevels)

        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: 100, error: nil)
        let configuration2 = LineLengthConfiguration(length: length2)
        XCTAssertEqual(configuration2.length, length2)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresURLs() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresURLs: true)

        XCTAssertTrue(configuration1.ignoresURLs)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        XCTAssertFalse(configuration2.ignoresURLs)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresFunctionDeclarations: true)
        XCTAssertTrue(configuration1.ignoresFunctionDeclarations)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        XCTAssertFalse(configuration2.ignoresFunctionDeclarations)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresComments() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresComments: true)
        XCTAssertTrue(configuration1.ignoresComments)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        XCTAssertFalse(configuration2.ignoresComments)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresInterpolatedStrings() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresInterpolatedStrings: true)
        XCTAssertTrue(configuration1.ignoresInterpolatedStrings)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        XCTAssertFalse(configuration2.ignoresInterpolatedStrings)
    }

    func testLineLengthConfigurationInitialiserSetsExcludedLinesPatterns() {
        let patterns: Set = ["foo", "bar"]
        let configuration1 = LineLengthConfiguration(length: severityLevels, excludedLinesPatterns: patterns)
        XCTAssertEqual(configuration1.excludedLinesPatterns, patterns)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        XCTAssertTrue(configuration2.excludedLinesPatterns.isEmpty)
    }

    func testLineLengthConfigurationParams() {
        let warning = 13
        let error = 10
        let configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: warning, error: error))
        let params = [RuleParameter(severity: .error, value: error), RuleParameter(severity: .warning, value: warning)]
        XCTAssertEqual(configuration.params, params)
    }

    func testLineLengthConfigurationPartialParams() {
        let configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 13))
        XCTAssertEqual(configuration.params, [RuleParameter(severity: .warning, value: 13)])
    }

    func testLineLengthConfigurationThrowsOnBadConfig() {
        let config = ["warning": "unknown"]
        var configuration = LineLengthConfiguration(length: severityLevels)
        checkError(Issue.invalidConfiguration(ruleID: LineLengthRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    func testLineLengthConfigurationThrowsOnBadConfigValues() {
        let badConfigs: [[String: Any]] = [
            ["warning": true],
            ["ignores_function_declarations": 300],
        ]

        for badConfig in badConfigs {
            var configuration = LineLengthConfiguration(length: severityLevels)
            checkError(Issue.invalidConfiguration(ruleID: LineLengthRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

    func testLineLengthConfigurationApplyConfigurationWithArray() {
        var configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 0, error: 0))

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning1, error: error1)
        let config1 = [warning1, error1]

        let warning2 = 150
        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning2, error: nil)
        let config2 = [warning2]

        do {
            try configuration.apply(configuration: config1)
            XCTAssertEqual(configuration.length, length1)

            try configuration.apply(configuration: config2)
            XCTAssertEqual(configuration.length, length2)
        } catch {
            XCTFail("Failed to apply configuration with array")
        }
    }

    func testLineLengthConfigurationApplyConfigurationWithDictionary() {
        var configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 0, error: 0))

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning1, error: error1)
        let config1: [String: Any] = [
            "warning": warning1,
            "error": error1,
            "ignores_urls": true,
            "ignores_function_declarations": true,
            "ignores_comments": true,
        ]

        let warning2 = 200
        let error2 = 200
        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning2, error: error2)
        let config2: [String: Int] = ["warning": warning2, "error": error2]

        let length3 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning2)
        let config3: [String: Bool] = [
            "ignores_urls": false,
            "ignores_function_declarations": false,
            "ignores_comments": false,
        ]

        do {
            try configuration.apply(configuration: config1)
            XCTAssertEqual(configuration.length, length1)
            XCTAssertTrue(configuration.ignoresURLs)
            XCTAssertTrue(configuration.ignoresFunctionDeclarations)
            XCTAssertTrue(configuration.ignoresComments)

            try configuration.apply(configuration: config2)
            XCTAssertEqual(configuration.length, length2)
            XCTAssertTrue(configuration.ignoresURLs)
            XCTAssertTrue(configuration.ignoresFunctionDeclarations)
            XCTAssertTrue(configuration.ignoresComments)

            try configuration.apply(configuration: config3)
            XCTAssertEqual(configuration.length, length3)
            XCTAssertFalse(configuration.ignoresURLs)
            XCTAssertFalse(configuration.ignoresFunctionDeclarations)
            XCTAssertFalse(configuration.ignoresComments)
        } catch {
            XCTFail("Failed to apply configuration with dictionary")
        }
    }

    func testLineLengthConfigurationCompares() {
        let configuration1 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 100))
        let configuration2 = LineLengthConfiguration(
            length: SeverityLevelsConfiguration(warning: 100, error: 100),
            ignoresFunctionDeclarations: true,
            ignoresComments: true
        )
        XCTAssertNotEqual(configuration1, configuration2)

        let configuration3 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 200))
        XCTAssertNotEqual(configuration1, configuration3)

        let configuration4 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 200, error: 200))
        XCTAssertNotEqual(configuration1, configuration4)

        let configuration5 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 100))
        XCTAssertEqual(configuration1, configuration5)

        let configuration6 = LineLengthConfiguration(
            length: SeverityLevelsConfiguration(warning: 100, error: 100),
            ignoresFunctionDeclarations: true,
            ignoresComments: true
        )
        XCTAssertEqual(configuration2, configuration6)
    }
}
