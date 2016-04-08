//
//  ConfigurationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import SourceKittenFramework
import XCTest

let optInRules = masterRuleList.list.filter({ $0.1.init() is OptInRule }).map({ $0.0 })

extension Configuration {
    var disabledRules: [String] {
        let configuredRuleIDs = rules.map({ $0.dynamicType.description.identifier })
        let defaultRuleIDs = Set(masterRuleList.list.values.filter({
            !($0.init() is OptInRule)
        }).map({ $0.description.identifier }))
        return defaultRuleIDs.subtract(configuredRuleIDs).sort(<)
    }
}

class ConfigurationTests: XCTestCase {

    func testInit() {
        XCTAssert(Configuration(dict: [:]) != nil,
            "initializing Configuration with empty Dictionary should succeed")
        XCTAssert(Configuration(dict: ["a": 1, "b": 2]) != nil,
            "initializing Configuration with valid Dictionary should succeed")
    }

    func testEmptyConfiguration() {
        guard let config = Configuration(dict: [:]) else {
            XCTFail("empty YAML string should yield non-nil Configuration")
            return
        }
        XCTAssertEqual(config.disabledRules, [])
        XCTAssertEqual(config.included, [])
        XCTAssertEqual(config.excluded, [])
        XCTAssertEqual(config.reporter, "xcode")
        XCTAssertEqual(reporterFromString(config.reporter).identifier, "xcode")
    }

    func testWhitelistRules() {
        let whitelist = ["nesting", "todo"]
        let config = Configuration(dict: ["whitelist_rules":  whitelist])!
        let configuredIdentifiers = config.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(whitelist, configuredIdentifiers)
    }

    func testOtherRuleConfigurationsAlongsideWhitelistRules() {
        let whitelist = ["nesting", "todo"]
        let enabledRulesConfigDict = [
            "opt_in_rules": ["line_length"],
            "whitelist_rules": whitelist
        ]
        let disabledRulesConfigDict = [
            "disabled_rules": ["variable_name"],
            "whitelist_rules": whitelist
        ]
        let combinedRulesConfigDict = enabledRulesConfigDict.reduce(disabledRulesConfigDict) {
            var d = $0; d[$1.0] = $1.1; return d
        }
        var configuration = Configuration(dict: enabledRulesConfigDict)
        XCTAssertNil(configuration)
        configuration = Configuration(dict: disabledRulesConfigDict)
        XCTAssertNil(configuration)
        configuration = Configuration(dict: combinedRulesConfigDict)
        XCTAssertNil(configuration)
    }

    func testDisabledRules() {
        let disabledConfig = Configuration(dict: ["disabled_rules":  ["nesting", "todo"]])!
        XCTAssertEqual(disabledConfig.disabledRules,
            ["nesting", "todo"],
            "initializing Configuration with valid rules in Dictionary should succeed")
        let expectedIdentifiers = Array(masterRuleList.list.keys)
            .filter({ !(["nesting", "todo"] + optInRules).contains($0) })
        let configuredIdentifiers = disabledConfig.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)

        // Duplicate
        let duplicateConfig = Configuration(dict: ["disabled_rules":  ["todo", "todo"]])
        XCTAssert(duplicateConfig == nil, "initializing Configuration with duplicate rules in " +
            "Dictionary should fail")
    }

    func testDisabledRulesWithUnknownRule() {
        let validRule = "nesting"
        let bogusRule = "no_sprites_with_elf_shoes"
        let configuration = Configuration(dict: ["disabled_rules": [validRule, bogusRule]])!

        XCTAssertEqual(configuration.disabledRules,
            [validRule],
            "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Array(masterRuleList.list.keys)
            .filter({ !([validRule] + optInRules).contains($0) })
        let configuredIdentifiers = configuration.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    private class TestFileManager: NSFileManager {
        private override func filesToLintAtPath(path: String) -> [String] {
            switch path {
            case "directory": return ["directory/File1.swift", "directory/File2.swift",
                "directory/excluded/Excluded.swift", "directory/ExcludedFile.swift"]
            case "directory/excluded" : return ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift" : return ["directory/ExcludedFile.swift"]
            default: break
            }
            XCTFail("Should not be called with path \(path)")
            return []
        }
    }

    func testExcludedPaths() {
        let configuration = Configuration(included: ["directory"],
            excluded: ["directory/excluded", "directory/ExcludedFile.swift"])!
        let paths = configuration.lintablePathsForPath("", fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    // MARK: - Testing Configuration Equality

    private var projectMockConfig0: Configuration {
        var configuration = Configuration(path: projectMockYAML0, optional: false, quiet: true)
        configuration.rootPath = projectMockPathLevel0
        return configuration
    }

    private var projectMockConfig2: Configuration {
        return Configuration(path: projectMockYAML2, optional: false, quiet: true)
    }

    func testIsEqualTo() {
        XCTAssertEqual(projectMockConfig0, projectMockConfig0)
    }

    func testIsNotEqualTo() {
        XCTAssertNotEqual(projectMockConfig0, projectMockConfig2)
    }

    // MARK: - Testing Nested Configurations

    func testMerge() {
        XCTAssertEqual(projectMockConfig0.merge(projectMockConfig2), projectMockConfig2)
    }

    func testLevel0() {
        XCTAssertEqual(projectMockConfig0.configurationForFile(File(path: projectMockSwift0)!),
                       projectMockConfig0)
    }

    func testLevel1() {
        XCTAssertEqual(projectMockConfig0.configurationForFile(File(path: projectMockSwift1)!),
                       projectMockConfig0)
    }

    func testLevel2() {
        XCTAssertEqual(projectMockConfig0.configurationForFile(File(path: projectMockSwift2)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    func testLevel3() {
        XCTAssertEqual(projectMockConfig0.configurationForFile(File(path: projectMockSwift3)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    // MARK: - Testing Rules from config dictionary

    let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    func testConfiguresCorrectlyFromDict() {
        let ruleConfiguration = [1, 2]
        let config = [RuleWithLevelsMock.description.identifier: ruleConfiguration]
        let rules = testRuleList.configuredRulesWithDictionary(config)
        // swiftlint:disable:next force_try
        XCTAssertTrue(rules == [try! RuleWithLevelsMock(configuration: ruleConfiguration) as Rule])
    }

    func testConfigureFallsBackCorrectly() {
        let config = [RuleWithLevelsMock.description.identifier: ["a", "b"]]
        let rules = testRuleList.configuredRulesWithDictionary(config)
        XCTAssertTrue(rules == [RuleWithLevelsMock() as Rule])
    }
}

// MARK: - ProjectMock Paths

extension String {
    func stringByAppendingPathComponent(pathComponent: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(pathComponent)
    }
}

extension XCTestCase {
    var bundlePath: String {
        #if SWIFT_PACKAGE
            return "Tests/SwiftLintFramework/Resources".absolutePathRepresentation()
        #else
            return NSBundle(forClass: self.dynamicType).resourcePath!
        #endif
    }

    var projectMockPathLevel0: String {
        return bundlePath.stringByAppendingPathComponent("ProjectMock")
    }

    var projectMockPathLevel1: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level1")
    }

    var projectMockPathLevel2: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level2")
    }

    var projectMockPathLevel3: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level3")
    }

    var projectMockYAML0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent(Configuration.fileName)
    }

    var projectMockYAML2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent(Configuration.fileName)
    }

    var projectMockSwift0: String {
        return projectMockPathLevel0.stringByAppendingPathComponent("Level0.swift")
    }

    var projectMockSwift1: String {
        return projectMockPathLevel1.stringByAppendingPathComponent("Level1.swift")
    }

    var projectMockSwift2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent("Level2.swift")
    }

    var projectMockSwift3: String {
        return projectMockPathLevel3.stringByAppendingPathComponent("Level3.swift")
    }
}
