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

private extension Configuration {
    var disabledRules: [String] {
        let configuredRuleIDs = rules.map({ type(of: $0).description.identifier })
        let defaultRuleIDs = Set(masterRuleList.list.values.filter({
            !($0.init() is OptInRule)
        }).map({ $0.description.identifier }))
        return defaultRuleIDs.subtracting(configuredRuleIDs).sorted(by: <)
    }
}

// swiftlint:disable type_body_length
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
        XCTAssertEqual(config.indentation, .spaces(count: 4))
        XCTAssertEqual(config.reporter, "xcode")
        XCTAssertEqual(reporterFrom(identifier: config.reporter).identifier, "xcode")
    }

    func testInitWithRelativePathAndRootPath() {
        let previousWorkingDir = FileManager.default.currentDirectoryPath
        let rootPath = projectMockSwift0
        let expectedConfig = projectMockConfig0
        FileManager.default.changeCurrentDirectoryPath(projectMockPathLevel0)

        let config = Configuration(path: ".swiftlint.yml", rootPath: rootPath,
                                   optional: false, quiet: true)

        XCTAssertEqual(config.disabledRules, expectedConfig.disabledRules)
        XCTAssertEqual(config.included, expectedConfig.included)
        XCTAssertEqual(config.excluded, expectedConfig.excluded)
        XCTAssertEqual(config.indentation, expectedConfig.indentation)
        XCTAssertEqual(config.reporter, expectedConfig.reporter)

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    func testEnableAllRulesConfiguration() {
        let configuration = Configuration(dict: [:], ruleList: masterRuleList, enableAllRules: true, cachePath: nil)!
        XCTAssertEqual(configuration.rules.count, masterRuleList.list.count)
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
            var dict = $0
            dict[$1.0] = $1.1
            return dict
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

    func testDuplicatedRules() {
        let duplicateConfig1 = Configuration(dict: ["whitelist_rules": ["todo", "todo"]])
        XCTAssertNil(duplicateConfig1, "initializing Configuration with duplicate rules in " +
            "Dictionary should fail")

        let duplicateConfig2 = Configuration(dict: ["opt_in_rules": [optInRules.first!, optInRules.first!]])
        XCTAssertNil(duplicateConfig2, "initializing Configuration with duplicate rules in " +
            "Dictionary should fail")

        let duplicateConfig3 = Configuration(dict: ["disabled_rules": ["todo", "todo"]])
        XCTAssertNil(duplicateConfig3, "initializing Configuration with duplicate rules in " +
            "Dictionary should fail")
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
        let paths = configuration.lintablePaths(inPath: "", forceExclude: false, fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesFile() {
        let configuration = Configuration(excluded: ["directory/ExcludedFile.swift"])!
        let paths = configuration.lintablePaths(inPath: "directory/ExcludedFile.swift", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual([], paths)
    }

    func testForceExcludesFileNotPresentInExcluded() {
        let configuration = Configuration(included: ["directory"],
                                          excluded: ["directory/ExcludedFile.swift", "directory/excluded"])!
        let paths = configuration.lintablePaths(inPath: "", forceExclude: true, fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesDirectory() {
        let configuration = Configuration(excluded: ["directory/excluded", "directory/ExcludedFile.swift"])!
        let paths = configuration.lintablePaths(inPath: "directory", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre() {
        let configuration = Configuration(excluded: ["directory/excluded", "directory/ExcludedFile.swift"])!
        let paths = configuration.lintablePaths(inPath: "directory", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testLintablePaths() {
        let paths = Configuration()!.lintablePaths(inPath: projectMockPathLevel0, forceExclude: false)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = [
            "DirectoryLevel1.swift",
            "Level0.swift",
            "Level1.swift",
            "Level2.swift",
            "Level3.swift"
        ]

        XCTAssertEqual(expectedFilenames, filenames)
    }

    // MARK: - Testing Configuration Equality

    func testIsEqualTo() {
        XCTAssertEqual(projectMockConfig0, projectMockConfig0)
    }

    func testIsNotEqualTo() {
        XCTAssertNotEqual(projectMockConfig0, projectMockConfig2)
    }

    // MARK: - Testing Custom Configuration File

    func testCustomConfiguration() {
        let file = File(path: projectMockSwift0)!
        XCTAssertNotEqual(projectMockConfig0.configuration(for: file),
                          projectMockConfig0CustomPath.configuration(for: file))
    }

    func testConfigurationWithSwiftFileAsRoot() {
        let configuration = Configuration(path: projectMockYAML0,
                                          rootPath: projectMockSwift0,
                                          optional: false, quiet: true)
        let file = File(path: projectMockSwift0)!
        XCTAssertEqual(configuration.configuration(for: file), configuration)
    }

    func testConfigurationWithSwiftFileAsRootAndCustomConfiguration() {
        let configuration = Configuration(path: projectMockYAML0CustomPath,
                                          rootPath: projectMockSwift0,
                                          optional: false, quiet: true)
        let file = File(path: projectMockSwift0)!
        XCTAssertEqual(configuration.configuration(for: file), configuration)
    }

    // MARK: - Testing custom indentation

    func testIndentationTabs() {
        let configuration = Configuration(dict: ["indentation": "tabs"])!
        XCTAssertEqual(configuration.indentation, .tabs)
    }

    func testIndentationSpaces() {
        let configuration = Configuration(dict: ["indentation": 2])!
        XCTAssertEqual(configuration.indentation, .spaces(count: 2))
    }

    func testIndentationFallback() {
        let configuration = Configuration(dict: ["indentation": "invalid"])!
        XCTAssertEqual(configuration.indentation, .spaces(count: 4))
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
