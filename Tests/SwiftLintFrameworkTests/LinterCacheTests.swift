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

    func testInitThrowsWhenUsingDifferentVersion() {
        let cache = ["version": "0.1.0"]
        checkError(LinterCacheError.differentVersion) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitSucceeds() {
        let cache = ["version": "0.2.0"]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        XCTAssertNotNil(linterCache)
    }

    func testParsesViolations() {
        var cache = LinterCache(currentVersion: Version(value: "0.2.0"))
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

        cache.cacheFile(file, violations: violations, hash: 1)
        let cachedViolations = cache.violations(for: file, hash: 1)

        XCTAssertNotNil(cachedViolations)
        XCTAssertEqual(cachedViolations!, violations)
    }

    func testParsesViolationsWithModifiedHash() {
        var cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        let file = "foo.swift"
        cache.cacheFile(file, violations: [], hash: 1)
        let cachedViolations = cache.violations(for: file, hash: 2)

        XCTAssertNil(cachedViolations)
    }

    func testParsesViolationsWithEmptyViolations() {
        let cache = LinterCache(currentVersion: Version(value: "0.2.0"))
        let file = "foo.swift"
        let cachedViolations = cache.violations(for: file, hash: 2)

        XCTAssertNil(cachedViolations)
    }
}
