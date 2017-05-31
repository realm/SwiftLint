//
//  ConfigurationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private let optInRules = masterRuleList.list.filter({ $0.1.init() is OptInRule }).map({ $0.0 })

extension Configuration {
    fileprivate var disabledRules: [String] {
        let configuredRuleIDs = rules.map({ type(of: $0).description.identifier })
        let defaultRuleIDs = Set(masterRuleList.list.values.filter({
            !($0.init() is OptInRule)
        }).map({ $0.description.identifier }))
        return defaultRuleIDs.subtracting(configuredRuleIDs).sorted(by: <)
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
        XCTAssertEqual(reporterFrom(identifier: config.reporter).identifier, "xcode")
    }

    func testWhitelistRules() {
        let whitelist = ["nesting", "todo"]
        let config = Configuration(dict: ["whitelist_rules": whitelist])!
        let configuredIdentifiers = config.rules.map {
            type(of: $0).description.identifier
        }.sorted()
        XCTAssertEqual(whitelist, configuredIdentifiers)
    }

    func testWarningThreshold_value() {
        let config = Configuration(dict: ["warning_threshold": 5])!
        XCTAssertEqual(config.warningThreshold, 5)
    }

    func testWarningThreshold_nil() {
        let config = Configuration(dict: [:])!
        XCTAssertEqual(config.warningThreshold, nil)
    }

    func testOtherRuleConfigurationsAlongsideWhitelistRules() {
        let whitelist = ["nesting", "todo"]
        let enabledRulesConfigDict = [
            "opt_in_rules": ["line_length"],
            "whitelist_rules": whitelist
        ]
        let disabledRulesConfigDict = [
            "disabled_rules": ["identifier_name"],
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
        let disabledConfig = Configuration(dict: ["disabled_rules": ["nesting", "todo"]])!
        XCTAssertEqual(disabledConfig.disabledRules,
                       ["nesting", "todo"],
                       "initializing Configuration with valid rules in Dictionary should succeed")
        let expectedIdentifiers = Set(masterRuleList.list.keys
            .filter({ !(["nesting", "todo"] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(disabledConfig.rules.map {
            type(of: $0).description.identifier
        })
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)

        // Duplicate
        let duplicateConfig = Configuration(dict: ["disabled_rules": ["todo", "todo"]])
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
        let expectedIdentifiers = Set(masterRuleList.list.keys
            .filter({ !([validRule] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(configuration.rules.map {
            type(of: $0).description.identifier
        })
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    private class TestFileManager: LintableFileManager {
        func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
            switch path {
            case "directory": return ["directory/File1.swift", "directory/File2.swift",
                                      "directory/excluded/Excluded.swift",
                                      "directory/ExcludedFile.swift"]
            case "directory/excluded" : return ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift" : return ["directory/ExcludedFile.swift"]
            default: break
            }
            XCTFail("Should not be called with path \(path)")
            return []
        }

        public func modificationDate(forFileAtPath path: String) -> Date? {
            return nil
        }
    }

    func testExcludedPaths() {
        let configuration = Configuration(included: ["directory"],
                                          excluded: ["directory/excluded",
                                                     "directory/ExcludedFile.swift"])!
        let paths = configuration.lintablePaths(inPath: "", fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    // MARK: - Testing Configuration Equality

    fileprivate var projectMockConfig0: Configuration {
        var configuration = Configuration(path: projectMockYAML0, optional: false, quiet: true)
        configuration.rootPath = projectMockPathLevel0
        return configuration
    }

    fileprivate var projectMockConfig2: Configuration {
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
        XCTAssertEqual(projectMockConfig0.merge(with: projectMockConfig2), projectMockConfig2)
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
                       projectMockConfig0.merge(with: projectMockConfig2))
    }

    // MARK: - Testing Rules from config dictionary

    let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    func testConfiguresCorrectlyFromDict() throws {
        let ruleConfiguration = [1, 2]
        let config = [RuleWithLevelsMock.description.identifier: ruleConfiguration]
        let rules = try testRuleList.configuredRules(with: config)
        XCTAssertTrue(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    func testConfigureFallsBackCorrectly() throws {
        let config = [RuleWithLevelsMock.description.identifier: ["a", "b"]]
        let rules = try testRuleList.configuredRules(with: config)
        XCTAssertTrue(rules == [RuleWithLevelsMock()])
    }

    // MARK: - Aliases

    func testConfiguresCorrectlyFromDeprecatedAlias() throws {
        let ruleConfiguration = [1, 2]
        let config = ["mock": ruleConfiguration]
        let rules = try testRuleList.configuredRules(with: config)
        XCTAssertTrue(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    func testReturnsNilWithDuplicatedConfiguration() {
        let dict = ["mock": [1, 2], "severity_level_mock": [1, 3]]
        let configuration = Configuration(dict: dict, ruleList: testRuleList)
        XCTAssertNil(configuration)
    }

    func testInitsFromDeprecatedAlias() {
        let ruleConfiguration = [1, 2]
        let configuration = Configuration(dict: ["mock": ruleConfiguration], ruleList: testRuleList)
        XCTAssertNotNil(configuration)
    }

    func testWhitelistRulesFromDeprecatedAlias() {
        let configuration = Configuration(dict: ["whitelist_rules": ["mock"]], ruleList: testRuleList)!
        let configuredIdentifiers = configuration.rules.map {
            type(of: $0).description.identifier
        }
        XCTAssertEqual(configuredIdentifiers, ["severity_level_mock"])
    }

    func testDisabledRulesFromDeprecatedAlias() {
        let configuration = Configuration(dict: ["disabled_rules": ["mock"]], ruleList: testRuleList)!
        XCTAssert(configuration.rules.isEmpty)
    }

}

// MARK: - ProjectMock Paths

fileprivate extension String {
    func stringByAppendingPathComponent(_ pathComponent: String) -> String {
        return bridge().appendingPathComponent(pathComponent)
    }
}

extension XCTestCase {
    var bundlePath: String {
        #if SWIFT_PACKAGE
            return "Tests/SwiftLintFrameworkTests/Resources".bridge().absolutePathRepresentation()
        #else
            return Bundle(for: type(of: self)).resourcePath!
        #endif
    }
}

fileprivate extension XCTestCase {

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
