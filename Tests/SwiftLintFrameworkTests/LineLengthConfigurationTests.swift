//
//  LineLengthConfigurationTests.swift
//  SwiftLint
//
//  Created by Javier Hernández on 05/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class LineLengthConfigurationTests: XCTestCase {
    let allFlags = LineLengthRuleOptions.all
    func testLineLengthConfigurationInitializerSetsLength() {
        let warning = 100
        let error = 150
        let length1 = SeverityLevelsConfiguration(warning: warning, error: error)
        let configuration1 = LineLengthConfiguration(warning: warning,
                                                     error: error,
                                                     options: allFlags)
        XCTAssertEqual(configuration1.length, length1)

        let length2 = SeverityLevelsConfiguration(warning: warning, error: nil)
        let configuration2 = LineLengthConfiguration(warning: warning,
                                                     error: nil,
                                                     options: allFlags)
        XCTAssertEqual(configuration2.length, length2)
    }

    func testLineLengthConfigurationInitialiserSetsIgnoresUrls() {
        let configuration1 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: [.ignoreUrls])

        XCTAssertTrue(configuration1.ignoresURLs)

        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 150,
                                                     options: nil)
        XCTAssertFalse(configuration2.ignoresURLs)
    }

    func testLineLengthConfigurationParams() {
        let warning = 13
        let error = 10
        let configuration = LineLengthConfiguration(warning: warning,
                                                    error: error,
                                                    options: [.ignoreFunctionDeclarations])
        let params = [RuleParameter(severity: .error, value: error), RuleParameter(severity: .warning, value: warning)]
        XCTAssertEqual(configuration.params, params)
    }

    func testLineLengthConfigurationPartialParams() {
        let warning = 13
        let configuration = LineLengthConfiguration(warning: warning,
                                                    error: nil,
                                                    options: [.ignoreFunctionDeclarations])
        XCTAssertEqual(configuration.params, [RuleParameter(severity: .warning, value: 13)])
    }

    func testLineLengthConfigurationThrowsOnBadConfig() {
        let config = "unknown"
        var configuration = LineLengthConfiguration(warning: 100, error: 150, options: allFlags)
        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: config)
        }
    }

    func testLineLengthConfigurationApplyConfigurationWithArray() {
        var configuration = LineLengthConfiguration(warning: 0, error: 0, options: nil)

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
            XCTFail()
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

        let length3 = SeverityLevelsConfiguration(warning: warning2, error: nil)
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
            XCTFail()
        }
    }

    func testLineLengthConfigurationCompares() {
        let configuration1 = LineLengthConfiguration(warning: 100, error: 100, options: allFlags)
        let configuration2 = LineLengthConfiguration(warning: 100,
                                                     error: 100,
                                                     options: [.ignoreFunctionDeclarations,
                                                               .ignoreComments])
        XCTAssertFalse(configuration1 == configuration2)

        let configuration3 = LineLengthConfiguration(warning: 100, error: 200, options: allFlags)
        XCTAssertFalse(configuration1 == configuration3)

        let configuration4 = LineLengthConfiguration(warning: 200, error: 100, options: allFlags)
        XCTAssertFalse(configuration1 == configuration4)

        let configuration5 = LineLengthConfiguration(warning: 100, error: 100, options: allFlags)
        XCTAssertTrue(configuration1 == configuration5)

        let configuration6 = LineLengthConfiguration(warning: 100,
                                                     error: 100,
                                                     options: [.ignoreFunctionDeclarations,
                                                               .ignoreComments])
        XCTAssertTrue(configuration2 == configuration6)
    }
}

extension LineLengthConfigurationTests {
    static var allTests: [(String, (LineLengthConfigurationTests) -> () throws -> Void)] {
        return [
            ("testLineLengthConfigurationInitializerSetsLength",
             testLineLengthConfigurationInitializerSetsLength),
            ("testLineLengthConfigurationInitialiserSetsIgnoresUrls",
             testLineLengthConfigurationInitialiserSetsIgnoresUrls),
            ("testLineLengthConfigurationPartialParams",
             testLineLengthConfigurationPartialParams),
            ("testLineLengthConfigurationParams",
             testLineLengthConfigurationParams),
            ("testLineLengthConfigurationThrowsOnBadConfig",
             testLineLengthConfigurationThrowsOnBadConfig),
            ("testLineLengthConfigurationApplyConfigurationWithArray",
             testLineLengthConfigurationApplyConfigurationWithArray),
            ("testLineLengthConfigurationApplyConfigurationWithDictionary",
             testLineLengthConfigurationApplyConfigurationWithDictionary),
            ("testLineLengthConfigurationCompares",
             testLineLengthConfigurationCompares)
        ]
    }
}
