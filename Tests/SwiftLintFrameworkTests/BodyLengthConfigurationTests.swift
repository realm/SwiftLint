//
//  BodyLengthConfigurationTests.swift
//  SwiftLint
//
//  Created by Daniel Rodriguez Troitino on 3/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class BodyLengthConfigurationTests: XCTestCase {
    func testBodyLengthConfigurationFromSeverityLevelsArray() {
        var configuration = BodyLengthConfiguration(warning: 0, error: 0)

        let configurationArray = [123, 456]

        do {
            try configuration.apply(configuration: configurationArray)
            XCTAssertEqual(configuration.warning, 123)
            XCTAssertEqual(configuration.error, 456)
        } catch {
            XCTFail()
        }
    }

    func testBodyLengthConfigurationFromSeverityLevelsDictionary() {
        var configuration = BodyLengthConfiguration(warning: 0, error: 0)

        let configurationDict = ["warning": 123, "error": 456]

        do {
            try configuration.apply(configuration: configurationDict)
            XCTAssertEqual(configuration.warning, 123)
            XCTAssertEqual(configuration.error, 456)
        } catch {
            XCTFail()
        }
    }

    func testBodyLengthConfigurationWithExcludedTypes() {
        var configuration = BodyLengthConfiguration(warning: 0, error: 0)

        let configurationDict: [String: Any] = [
            "warning": 123,
            "error": 456,
            "excluded": ["regex1", "regex2"]
        ]

        do {
            try configuration.apply(configuration: configurationDict)
            XCTAssertEqual(configuration.warning, 123)
            XCTAssertEqual(configuration.error, 456)
            XCTAssertEqual(configuration.excluded.count, 2)
            XCTAssert(Array(configuration.excluded).map { $0.pattern }.contains("regex1"))
            XCTAssert(Array(configuration.excluded).map { $0.pattern }.contains("regex2"))
        } catch {
            XCTFail()
        }
    }

    func testBodyLengthConfigurationWithOnlyExcluded() {
        var configuration = BodyLengthConfiguration(warning: 123, error: 456)

        let configurationDict: [String: Any] = [
            "excluded": ["regex1", "regex2"]
        ]

        do {
            try configuration.apply(configuration: configurationDict)
            XCTAssertEqual(configuration.warning, 123)
            XCTAssertEqual(configuration.error, 456)
            XCTAssertEqual(configuration.excluded.count, 2)
            XCTAssert(Array(configuration.excluded).map { $0.pattern }.contains("regex1"))
            XCTAssert(Array(configuration.excluded).map { $0.pattern }.contains("regex2"))
        } catch {
            XCTFail()
        }
    }

    func testBodyLengthConfigurationWithInvalidConfiguration() {
        var configuration = BodyLengthConfiguration(warning: 0, error: 0)

        let configurationDict: [String: Any] = [
            "warning": 123,
            "error": 456,
            "foobar": ["regex1", "regex2"]
        ]

        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: configurationDict)
        }
    }
}

extension BodyLengthConfigurationTests {
    static var allTests: [(String, (BodyLengthConfigurationTests) -> () throws -> Void)] {
        return [
            ("testBodyLengthConfigurationFromSeverityLevelsArray",
             testBodyLengthConfigurationFromSeverityLevelsArray),
            ("testBodyLengthConfigurationFromSeverityLevelsDictionary",
             testBodyLengthConfigurationFromSeverityLevelsDictionary),
            ("testBodyLengthConfigurationWithExcludedTypes",
             testBodyLengthConfigurationWithExcludedTypes),
            ("testBodyLengthConfigurationWithInvalidConfiguration",
             testBodyLengthConfigurationWithInvalidConfiguration)
        ]
    }
}
