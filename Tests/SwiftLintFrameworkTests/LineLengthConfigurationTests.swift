@testable import SwiftLintBuiltInRules
import XCTest

class LineLengthConfigurationTests: SwiftLintTestCase {
    func testLineLengthConfigurationInitializerSetsLength() {
        let warning = 100
        let error = 150
        let length1 = SeverityLevelsConfiguration(warning: warning, error: error)
        let configuration1 = LineLengthConfiguration(warning: warning,
                                                     error: error)
        XCTAssertEqual(configuration1.length, length1)

        let length2 = SeverityLevelsConfiguration(warning: warning, error: nil)
        let configuration2 = LineLengthConfiguration(warning: warning,
                                                     error: nil)
        XCTAssertEqual(configuration2.length, length2)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresURLs() {
        let configuration1 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: [.ignoreURLs])

        XCTAssertTrue(configuration1.ignoresURLs)

        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 150)
        XCTAssertFalse(configuration2.ignoresURLs)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations() {
        let configuration1 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: [.ignoreFunctionDeclarations])

        XCTAssertTrue(configuration1.ignoresFunctionDeclarations)

        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 150)
        XCTAssertFalse(configuration2.ignoresFunctionDeclarations)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresComments() {
        let configuration1 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: [.ignoreComments])

        XCTAssertTrue(configuration1.ignoresComments)

        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 150)
        XCTAssertFalse(configuration2.ignoresComments)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresInterpolatedStrings() {
        let configuration1 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: [.ignoreInterpolatedStrings])

        XCTAssertTrue(configuration1.ignoresInterpolatedStrings)

        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 150)
        XCTAssertFalse(configuration2.ignoresInterpolatedStrings)
    }

    func testLineLengthConfigurationParams() {
        let warning = 13
        let error = 10
        let configuration = LineLengthConfiguration(warning: warning,
                                                    error: error)
        let params = [RuleParameter(severity: .error, value: error), RuleParameter(severity: .warning, value: warning)]
        XCTAssertEqual(configuration.params, params)
    }

    func testLineLengthConfigurationPartialParams() {
        let warning = 13
        let configuration = LineLengthConfiguration(warning: warning,
                                                    error: nil)
        XCTAssertEqual(configuration.params, [RuleParameter(severity: .warning, value: 13)])
    }

    func testLineLengthConfigurationThrowsOnBadConfig() {
        let config = "unknown"
        var configuration = LineLengthConfiguration(warning: 100, error: 150)
        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: config)
        }
    }

    func testLineLengthConfigurationThrowsOnBadConfigValues() {
        let badConfigs: [[String: Any]] = [
            ["warning": true],
            ["ignores_function_declarations": 300],
            ["unsupported_key": "unsupported key is unsupported"]
        ]

        for badConfig in badConfigs {
            var configuration = LineLengthConfiguration(warning: 100, error: 150)
            checkError(ConfigurationError.unknownConfiguration) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

    func testLineLengthConfigurationApplyConfigurationWithArray() {
        var configuration = LineLengthConfiguration(warning: 0, error: 0)

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration(warning: warning1, error: error1)
        let config1 = [warning1, error1]

        let warning2 = 150
        let length2 = SeverityLevelsConfiguration(warning: warning2, error: nil)
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
        var configuration = LineLengthConfiguration(warning: 0, error: 0)

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration(warning: warning1, error: error1)
        let config1: [String: Any] = ["warning": warning1,
                                      "error": error1,
                                      "ignores_urls": true,
                                      "ignores_function_declarations": true,
                                      "ignores_comments": true]

        let warning2 = 200
        let error2 = 200
        let length2 = SeverityLevelsConfiguration(warning: warning2, error: error2)
        let config2: [String: Int] = ["warning": warning2, "error": error2]

        let length3 = SeverityLevelsConfiguration(warning: warning2, error: error2)
        let config3: [String: Bool] = ["ignores_urls": false,
                                       "ignores_function_declarations": false,
                                       "ignores_comments": false]

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
        let configuration1 = LineLengthConfiguration(warning: 100, error: 100)
        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 100,
                                                     options: [.ignoreFunctionDeclarations,
                                                               .ignoreComments])
        XCTAssertFalse(configuration1 == configuration2)

        let configuration3 = LineLengthConfiguration(warning: 100, error: 200)
        XCTAssertFalse(configuration1 == configuration3)

        let configuration4 = LineLengthConfiguration(warning: 200, error: 100)
        XCTAssertFalse(configuration1 == configuration4)

        let configuration5 = LineLengthConfiguration(warning: 100, error: 100)
        XCTAssertTrue(configuration1 == configuration5)

        let configuration6 = LineLengthConfiguration(warning: 100,
                                                     error: 100,
                                                     options: [.ignoreFunctionDeclarations,
                                                               .ignoreComments])
        XCTAssertTrue(configuration2 == configuration6)
    }
}
