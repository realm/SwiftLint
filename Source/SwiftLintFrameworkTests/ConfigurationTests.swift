//
//  ConfigurationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class ConfigurationTests: XCTestCase {
    func testInit() {
        XCTAssert(Configuration(yaml: "") != nil,
            "initializing Configuration with empty YAML string should succeed")
        XCTAssert(Configuration(yaml: "a: 1\nb: 2") != nil,
            "initializing Configuration with valid YAML string should succeed")
        XCTAssert(Configuration(yaml: "|\na") == nil,
            "initializing Configuration with invalid YAML string should fail")
    }

    func testEmptyConfiguration() {
        guard let config = Configuration(yaml: "") else {
            XCTFail("empty YAML string should yield non-nil Configuration")
            return
        }
        XCTAssertEqual(config.disabledRules, [])
        XCTAssertEqual(config.included, [])
        XCTAssertEqual(config.excluded, [])
        XCTAssertEqual(config.reporter, "xcode")
        XCTAssertEqual(config.reporterFromString.identifier, "xcode")
    }

    func testDisabledRules() {
        XCTAssert(Configuration(yaml: "disabled_rules:\n  - a") == nil,
            "initializing Configuration with invalid rules in YAML string should fail")
        let disabledConfig = Configuration(yaml: "disabled_rules:\n  - nesting\n  - todo")!
        XCTAssertEqual(disabledConfig.disabledRules,
            ["nesting", "todo"],
            "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = allRules
            .map({ $0.identifier })
            .filter({ !["nesting", "todo"].contains($0) })
        let configuredIdentifiers = disabledConfig.rules.map({ $0.identifier })
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)

        // Duplicate
        let duplicateConfig = Configuration( yaml: "disabled_rules:\n  - todo\n  - todo")
        XCTAssert(duplicateConfig == nil, "initializing Configuration with duplicate rules in " +
            " YAML string should fail")
    }
}
