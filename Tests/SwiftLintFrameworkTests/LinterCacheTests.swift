//
//  LinterCacheTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class LinterCacheTests: XCTestCase {

    private class TestFileManager: LintableFileManager {
        func filesToLint(inPath: String, rootDirectory: String? = nil) -> [String] {
            return []
        }

        internal var stubbedModificationDateByPath: [String: Date] = [:]

        public func modificationDate(forFileAtPath path: String) -> Date? {
            return stubbedModificationDateByPath[path]
        }
    }

    private let fileManager = TestFileManager()

    func testInitThrowsWhenUsingDifferentVersion() {
        let cache = ["version": "0.1.0"]
        checkError(LinterCacheError.differentVersion) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.1.0"))
        }
    }

    func testInitThrowsWhenUsingDifferentConfiguration() {
        let cache = ["version": "0.1.0", "configuration": "Configuration 1"] as [String : Any]
        checkError(LinterCacheError.differentConfiguration) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.1.0"),
                                configurationDescription: "Configuration 2")
        }
    }

    func testInitSucceeds() {
        let cache = ["version": "0.2.0"]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        XCTAssertNotNil(linterCache)
    }

    func testInitSucceedsWithConfiguration() {
        let cache = ["version": "0.2.0", "configuration": "Configuration 1"] as [String : Any]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"),
                                           configurationDescription: "Configuration 1")
        XCTAssertNotNil(linterCache)
    }

    func testParsesViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        cache.fileManager = fileManager
        let file = "foo.swift"
        let ruleDescription = RuleDescription(identifier: "rule", name: "Some rule",
                                              description: "Validates stuff")
        let violations = [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]
        fileManager.stubbedModificationDateByPath[file] = Date()

        cache.cache(violations: violations, forFile: file)
        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNotNil(cachedViolations)
        XCTAssertEqual(cachedViolations!, violations)
    }

    func testParsesViolationsWithEmptyViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        cache.fileManager = fileManager
        let file = "foo.swift"
        fileManager.stubbedModificationDateByPath[file] = Date()

        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNil(cachedViolations)
    }

    func testParsesViolationsWithNoDate() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        cache.fileManager = fileManager
        let file = "foo.swift"
        let ruleDescription = RuleDescription(identifier: "rule", name: "Some rule",
                                              description: "Validates stuff")
        let violations = [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]
        fileManager.stubbedModificationDateByPath[file] = Date()

        cache.cache(violations: violations, forFile: file)
        fileManager.stubbedModificationDateByPath[file] = nil
        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNil(cachedViolations)
    }

    func testParsesViolationsWithDifferentDate() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        cache.fileManager = fileManager
        let file = "foo.swift"
        let ruleDescription = RuleDescription(identifier: "rule", name: "Some rule",
                                              description: "Validates stuff")
        let violations = [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]
        fileManager.stubbedModificationDateByPath[file] = Date()

        cache.cache(violations: violations, forFile: file)
        fileManager.stubbedModificationDateByPath[file] = Date()
        let cachedViolations = cache.violations(forFile: file)

        XCTAssertNil(cachedViolations)
    }
}

extension LinterCacheTests {
    static var allTests: [(String, (LinterCacheTests) -> () throws -> Void)] {
        return [
            ("testInitThrowsWhenUsingDifferentVersion", testInitThrowsWhenUsingDifferentVersion),
            ("testInitThrowsWhenUsingInvalidCacheFormat", testInitThrowsWhenUsingInvalidCacheFormat),
            ("testInitThrowsWhenUsingDifferentConfiguration", testInitThrowsWhenUsingDifferentConfiguration),
            ("testInitSucceeds", testInitSucceeds),
            ("testInitSucceedsWithConfiguration", testInitSucceedsWithConfiguration),
            ("testParsesViolations", testParsesViolations),
            ("testParsesViolationsWithEmptyViolations", testParsesViolationsWithEmptyViolations),
            ("testParsesViolationsWithNoDate", testParsesViolationsWithNoDate),
            ("testParsesViolationsWithDifferentDate", testParsesViolationsWithDifferentDate)
        ]
    }
}
