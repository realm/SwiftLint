@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class CyclomaticComplexityConfigurationTests: SwiftLintTestCase {
    func testCyclomaticComplexityConfigurationInitializerSetsLevels() {
        let warning = 10
        let error = 30
        let level = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning, error: error)
        let configuration1 = CyclomaticComplexityConfiguration(length: level)
        XCTAssertEqual(configuration1.length, level)

        let length2 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning, error: nil)
        let configuration2 = CyclomaticComplexityConfiguration(length: length2)
        XCTAssertEqual(configuration2.length, length2)
    }

    func testCyclomaticComplexityConfigurationInitializerSetsIgnoresCaseStatements() {
        let configuration1 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: true
        )
        XCTAssertTrue(configuration1.ignoresCaseStatements)

        let configuration2 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30)
        )
        XCTAssertFalse(configuration2.ignoresCaseStatements)
    }

    func testCyclomaticComplexityConfigurationApplyConfigurationWithDictionary() throws {
        var configuration = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 0, error: 0)
        )

        let warning1 = 10
        let error1 = 30
        let length1 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning1, error: error1)
        let config1: [String: Any] = [
            "warning": warning1,
            "error": error1,
            "ignores_case_statements": true,
        ]

        let warning2 = 20
        let error2 = 40
        let length2 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning2, error: error2)
        let config2: [String: Int] = ["warning": warning2, "error": error2]
        let length3 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning2)
        let config3: [String: Bool] = ["ignores_case_statements": false]

        try configuration.apply(configuration: config1)
        XCTAssertEqual(configuration.length, length1)
        XCTAssertTrue(configuration.ignoresCaseStatements)

        try configuration.apply(configuration: config2)
        XCTAssertEqual(configuration.length, length2)
        XCTAssertTrue(configuration.ignoresCaseStatements)

        try configuration.apply(configuration: config3)
        XCTAssertEqual(configuration.length, length3)
        XCTAssertFalse(configuration.ignoresCaseStatements)
    }

    func testCyclomaticComplexityConfigurationThrowsOnBadConfigValues() {
        let badConfigs: [[String: Any]] = [
            ["warning": true],
            ["ignores_case_statements": 300],
        ]

        for badConfig in badConfigs {
            var configuration = CyclomaticComplexityConfiguration(
                length: SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: 100, error: 150)
            )
            checkError(Issue.invalidConfiguration(ruleID: CyclomaticComplexityRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

    func testCyclomaticComplexityConfigurationCompares() {
        let config1 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30)
        )
        let config2 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: true
        )
        let config3 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: false
        )
        let config4 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 40)
        )
        let config5 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 20, error: 30)
        )
        XCTAssertNotEqual(config1, config2)
        XCTAssertEqual(config1, config3)
        XCTAssertNotEqual(config1, config4)
        XCTAssertNotEqual(config1, config5)
    }
}
