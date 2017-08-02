//
//  ConfigurationTests+Nested.swift
//  SwiftLint
//
//  Created by Stéphane Copin on 7/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private extension Configuration {
    func contains<T: Rule>(rule: T.Type) -> Bool {
        return rules.contains { $0 is T }
    }
}

extension ConfigurationTests {
    func testMerge() {
        XCTAssertFalse(projectMockConfig0.contains(rule: ForceCastRule.self))
        XCTAssertTrue(projectMockConfig2.contains(rule: ForceCastRule.self))
        let config0Merge2 = projectMockConfig0.merge(with: projectMockConfig2)
        XCTAssertFalse(config0Merge2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(projectMockConfig0.contains(rule: TodoRule.self))
        XCTAssertTrue(projectMockConfig2.contains(rule: TodoRule.self))
        XCTAssertTrue(config0Merge2.contains(rule: TodoRule.self))
        XCTAssertFalse(projectMockConfig3.contains(rule: TodoRule.self))
        XCTAssertFalse(config0Merge2.merge(with: projectMockConfig3).contains(rule: TodoRule.self))
    }

    func testLevel0() {
        XCTAssertEqual(projectMockConfig0.configuration(for: File(path: projectMockSwift0)!),
                       projectMockConfig0)
    }

    func testLevel1() {
        XCTAssertEqual(projectMockConfig0.configuration(for: File(path: projectMockSwift1)!),
                       projectMockConfig0)
    }

    func testLevel2() {
        XCTAssertEqual(projectMockConfig0.configuration(for: File(path: projectMockSwift2)!),
                       projectMockConfig0.merge(with: projectMockConfig2))
    }

    func testLevel3() {
        XCTAssertEqual(projectMockConfig0.configuration(for: File(path: projectMockSwift3)!),
                       projectMockConfig0.merge(with: projectMockConfig3))
    }

    func testNestedConfigurationWithCustomRootPath() {
        XCTAssertNotEqual(projectMockConfig0.rootPath, projectMockConfig3.rootPath)
        XCTAssertEqual(projectMockConfig0.merge(with: projectMockConfig3).rootPath, projectMockConfig3.rootPath)
    }

    func testMergedWarningThreshold() {
        func configuration(forWarningThreshold warningThreshold: Int?) -> Configuration {
            return Configuration(warningThreshold: warningThreshold,
                                 reporter: XcodeReporter.identifier,
                                 ruleList: masterRuleList)!
        }
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merge(with: configuration(forWarningThreshold: 2)).warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: nil)
            .merge(with: configuration(forWarningThreshold: 2)).warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merge(with: configuration(forWarningThreshold: nil)).warningThreshold,
                       3)
        XCTAssertEqual(configuration(forWarningThreshold: nil)
            .merge(with: configuration(forWarningThreshold: nil)).warningThreshold,
                       nil)
    }

    func testNestedWhitelistedRules() {
        let baseConfiguration = Configuration(rulesMode: .default(disabled: [],
                                                                  optIn: [ForceTryRule.description.identifier,
                                                                          ForceCastRule.description.identifier]))!
        let whitelistedConfiguration = Configuration(rulesMode: .whitelisted([TodoRule.description.identifier]))!
        XCTAssertTrue(baseConfiguration.contains(rule: TodoRule.self))
        XCTAssertEqual(whitelistedConfiguration.rules.count, 1)
        XCTAssertTrue(whitelistedConfiguration.rules[0] is TodoRule)
        let mergedConfiguration1 = baseConfiguration.merge(with: whitelistedConfiguration)
        XCTAssertEqual(mergedConfiguration1.rules.count, 1)
        XCTAssertTrue(mergedConfiguration1.rules[0] is TodoRule)

        // Also test the other way around
        let mergedConfiguration2 = whitelistedConfiguration.merge(with: baseConfiguration)
        XCTAssertEqual(mergedConfiguration2.rules.count, 3) // 2 opt-ins + 1 from the whitelisted rules
        XCTAssertTrue(mergedConfiguration2.contains(rule: TodoRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceTryRule.self))
    }
}
