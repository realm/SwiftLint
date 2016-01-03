//
//  ConfigurationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import SourceKittenFramework
import XCTest

class ConfigurationTests: XCTestCase {
    func testInit() {
        XCTAssert(Configuration(dict: [:]) != nil,
            "initializing Configuration with empty Dictionary should succeed")
        XCTAssert(Configuration(dict: ["a" : 1, "b" : 2]) != nil,
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
        XCTAssertEqual(config.reporterFromString.identifier, "xcode")
    }

    func testDisabledRules() {
        let disabledConfig = Configuration(dict: ["disabled_rules" :  ["nesting", "todo"]])!
        XCTAssertEqual(disabledConfig.disabledRules,
            ["nesting", "todo"],
            "initializing Configuration with valid rules in Dictionary should succeed")
        let expectedIdentifiers = Array(masterRuleList.list.keys)
            .filter({ !["nesting", "todo"].contains($0) })
        let configuredIdentifiers = disabledConfig.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)

        // Duplicate
        let duplicateConfig = Configuration(dict: ["disabled_rules" :  ["todo", "todo"]])
        XCTAssert(duplicateConfig == nil, "initializing Configuration with duplicate rules in " +
            " Dictionary should fail")
    }

    func testDisabledRulesWithUnknownRule() {
        let validRule = "nesting"
        let bogusRule = "no_sprites_with_elf_shoes"
        let configuration = Configuration(dict: ["disabled_rules" : [validRule, bogusRule]])!

        XCTAssertEqual(configuration.disabledRules,
            [validRule],
            "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Array(masterRuleList.list.keys)
            .filter({ ![validRule].contains($0) })
        let configuredIdentifiers = configuration.rules.map {
            $0.dynamicType.description.identifier
        }
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    private class TestFileManager: NSFileManager {
        private override func filesToLintAtPath(path: String) -> [String] {
            switch path {
            case "directory": return ["directory/File1.swift", "directory/File2.swift",
                "directory/excluded/Excluded.swift",  "directory/ExcludedFile.swift"]
            case "directory/excluded" : return ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift" : return ["directory/ExcludedFile.swift"]
            default: break
            }
            XCTFail("Should not be called with path \(path)")
            return []
        }
    }

    func testExcludedPaths() {
        let configuration = Configuration(disabledRules: [], included: ["directory"],
            excluded: ["directory/excluded",  "directory/ExcludedFile.swift"],
            reporter: "json", rules: [])!
        let paths = configuration.lintablePathsForPath("", fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    // MARK: - Testing Configuration Equality

    private var projectMockConfig0: Configuration {
        var config = Configuration(path: projectMockYAML0, optional: false, silent: true)
        config.rootPath = projectMockPathLevel0
        return config
    }

    private var projectMockConfig2: Configuration {
        return Configuration(path: projectMockYAML2, optional: false, silent: true)
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
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift0)!),
                       projectMockConfig0)
    }

    func testLevel1() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift1)!),
                       projectMockConfig0)
    }

    func testLevel2() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift2)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    func testLevel3() {
        XCTAssertEqual(projectMockConfig0.configForFile(File(path: projectMockSwift3)!),
                       projectMockConfig0.merge(projectMockConfig2))
    }

    func testDoNotUseNestedConfigs() {
        var config = Configuration(dict: ["use_nested_configs" : false])!
        config.rootPath = projectMockPathLevel0
        XCTAssertEqual(config.configForFile(File(path: projectMockSwift3)!),
                       config)
    }

    // MARK: - Testing Rules from config dictionary

    let testRuleList = RuleList(rules: ConfigurableRuleMock1.self)

    func testConfiguresCorrectlyFromDict() {
        let ruleConfig = [1, 2]
        let config = [ConfigurableRuleMock1.description.identifier: ruleConfig]
        let rules = Configuration.rulesFromDict(config, ruleList: testRuleList)
        XCTAssertTrue(rules == [ConfigurableRuleMock1(config: ruleConfig)! as Rule])
    }

    func testConfigureFallsBackCorrectly() {
        let config = [ConfigurableRuleMock1.description.identifier: ["a", "b"]]
        let rules = Configuration.rulesFromDict(config, ruleList: testRuleList)
        XCTAssertTrue(rules == [ConfigurableRuleMock1() as Rule])
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
        return NSBundle(forClass: self.dynamicType).resourcePath!
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
        return projectMockPathLevel0.stringByAppendingPathComponent(".swiftlint.yml")
    }

    var projectMockYAML2: String {
        return projectMockPathLevel2.stringByAppendingPathComponent(".swiftlint.yml")
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
