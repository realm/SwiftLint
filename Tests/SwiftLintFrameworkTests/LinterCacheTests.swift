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

private struct CacheTestHelper {
    fileprivate let configuration: Configuration

    private let ruleList: RuleList
    private let ruleDescription: RuleDescription
    private let cache: LinterCache

    private var fileManager: TestFileManager {
        // swiftlint:disable:next force_cast
        return cache.fileManager as! TestFileManager
    }

    fileprivate init(dict: [String: Any], cache: LinterCache) {
        ruleList = RuleList(rules: RuleWithLevelsMock.self)
        ruleDescription = ruleList.list.values.first!.description
        configuration = Configuration(dict: dict, ruleList: ruleList)!
        self.cache = cache
    }

    fileprivate func makeViolations(file: String) -> [StyleViolation] {
        touch(file: file)
        return [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right."),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong.")
        ]
    }

    fileprivate func makeConfig(dict: [String: Any]) -> Configuration {
        return Configuration(dict: dict, ruleList: ruleList)!
    }

    fileprivate func touch(file: String) {
        fileManager.stubbedModificationDateByPath[file] = Date()
    }

    fileprivate func remove(file: String) {
        fileManager.stubbedModificationDateByPath[file] = nil
    }

    fileprivate func fileCount() -> Int {
        return fileManager.stubbedModificationDateByPath.count
    }
}

private class TestFileManager: LintableFileManager {
    fileprivate func filesToLint(inPath: String, rootDirectory: String? = nil) -> [String] {
        return []
    }

    fileprivate var stubbedModificationDateByPath = [String: Date]()

    fileprivate func modificationDate(forFileAtPath path: String) -> Date? {
        return stubbedModificationDateByPath[path]
    }
}

class LinterCacheTests: XCTestCase {

    // MARK: Test Helpers

    private var cache = LinterCache(fileManager: TestFileManager())

    private func makeCacheTestHelper(dict: [String: Any]) -> CacheTestHelper {
        return CacheTestHelper(dict: dict, cache: cache)
    }

    private func cacheAndValidate(violations: [StyleViolation], forFile: String, configuration: Configuration,
                                  file: StaticString = #file, line: UInt = #line) {
        cache.cache(violations: violations, forFile: forFile, configuration: configuration)
        cache = cache.flushed()
        XCTAssertEqual(cache.violations(forFile: forFile, configuration: configuration)!,
                       violations, file: file, line: line)
    }

    private func cacheAndValidateNoViolationsTwoFiles(configuration: Configuration,
                                                      file: StaticString = #file, line: UInt = #line) {
        let (file1, file2) = ("file1.swift", "file2.swift")
        // swiftlint:disable:next force_cast
        let fileManager = cache.fileManager as! TestFileManager
        fileManager.stubbedModificationDateByPath = [file1: Date(), file2: Date()]

        cacheAndValidate(violations: [], forFile: file1, configuration: configuration, file: file, line: line)
        cacheAndValidate(violations: [], forFile: file2, configuration: configuration, file: file, line: line)
    }

    private func validateNewConfigDoesntHitCache(dict: [String: Any], initialConfig: Configuration,
                                                 file: StaticString = #file, line: UInt = #line) {
        let newConfig = Configuration(dict: dict)!
        let (file1, file2) = ("file1.swift", "file2.swift")

        XCTAssertNil(cache.violations(forFile: file1, configuration: newConfig), file: file, line: line)
        XCTAssertNil(cache.violations(forFile: file2, configuration: newConfig), file: file, line: line)

        XCTAssertEqual(cache.violations(forFile: file1, configuration: initialConfig)!, [], file: file, line: line)
        XCTAssertEqual(cache.violations(forFile: file2, configuration: initialConfig)!, [], file: file, line: line)
    }

    // MARK: Cache Initialization

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache)
        }
    }

    func testSaveThrowsWithNoLocation() throws {
        let cache = try LinterCache(cache: [:])
        checkError(LinterCacheError.noLocation) {
            try cache.save()
        }
    }

    func testInitSucceeds() {
        XCTAssertNotNil(try? LinterCache(cache: [:]))
    }

    // MARK: Cache Reuse

    // Two subsequent lints with no changes reuses cache
    func testUnchangedFilesReusesCache() {
        let helper = makeCacheTestHelper(dict: ["whitelist_rules": ["mock"]])
        let file = "foo.swift"
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        helper.touch(file: file)

        XCTAssertNil(cache.violations(forFile: file, configuration: helper.configuration))
    }

    func testConfigFileReorderedReusesCache() {
        let helper = makeCacheTestHelper(dict: ["whitelist_rules": ["mock"], "disabled_rules": []])
        let file = "foo.swift"
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["disabled_rules": [], "whitelist_rules": ["mock"]])
        XCTAssertEqual(cache.violations(forFile: file, configuration: configuration2)!, violations)
    }

    func testConfigFileWhitespaceAndCommentsChangedOrAddedOrRemovedReusesCache() throws {
        let helper = makeCacheTestHelper(dict: try YamlParser.parse("whitelist_rules:\n  - mock"))
        let file = "foo.swift"
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["disabled_rules": [], "whitelist_rules": ["mock"]])
        XCTAssertEqual(cache.violations(forFile: file, configuration: configuration2)!, violations)
        let configYamlWithComment = try YamlParser.parse("# comment1\nwhitelist_rules:\n  - mock # comment2")
        let configuration3 = helper.makeConfig(dict: configYamlWithComment)
        XCTAssertEqual(cache.violations(forFile: file, configuration: configuration3)!, violations)
        XCTAssertEqual(cache.violations(forFile: file, configuration: helper.configuration)!, violations)
    }

    func testConfigFileUnrelatedKeysChangedOrAddedOrRemovedReusesCache() {
        let helper = makeCacheTestHelper(dict: ["whitelist_rules": ["mock"], "reporter": "json"])
        let file = "foo.swift"
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["whitelist_rules": ["mock"], "reporter": "xcode"])
        XCTAssertEqual(cache.violations(forFile: file, configuration: configuration2)!, violations)
        let configuration3 = helper.makeConfig(dict: ["whitelist_rules": ["mock"]])
        XCTAssertEqual(cache.violations(forFile: file, configuration: configuration3)!, violations)
    }

    // MARK: Sing-File Cache Invalidation

    // Two subsequent lints with a file touch in between causes just that one
    // file to be re-linted, with the cache used for all other files
    func testChangedFileCausesJustThatFileToBeLintWithCacheUsedForAllOthers() {
        let helper = makeCacheTestHelper(dict: ["whitelist_rules": ["mock"], "reporter": "json"])
        let (file1, file2) = ("file1.swift", "file2.swift")
        let violations1 = helper.makeViolations(file: file1)
        let violations2 = helper.makeViolations(file: file2)

        cacheAndValidate(violations: violations1, forFile: file1, configuration: helper.configuration)
        cacheAndValidate(violations: violations2, forFile: file2, configuration: helper.configuration)
        helper.touch(file: file2)
        XCTAssertEqual(cache.violations(forFile: file1, configuration: helper.configuration)!, violations1)
        XCTAssertNil(cache.violations(forFile: file2, configuration: helper.configuration))
    }

    func testFileRemovedPreservesThatFileInTheCacheAndDoesntCauseAnyOtherFilesToBeLinted() {
        let helper = makeCacheTestHelper(dict: ["whitelist_rules": ["mock"], "reporter": "json"])
        let (file1, file2) = ("file1.swift", "file2.swift")
        let violations1 = helper.makeViolations(file: file1)
        let violations2 = helper.makeViolations(file: file2)

        cacheAndValidate(violations: violations1, forFile: file1, configuration: helper.configuration)
        cacheAndValidate(violations: violations2, forFile: file2, configuration: helper.configuration)
        XCTAssertEqual(helper.fileCount(), 2)
        helper.remove(file: file2)
        XCTAssertEqual(cache.violations(forFile: file1, configuration: helper.configuration)!, violations1)
        XCTAssertEqual(helper.fileCount(), 1)
    }

    // MARK: All-File Cache Invalidation

    func testCustomRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(
            dict: [
                "whitelist_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]inja)"]]
            ],
            ruleList: RuleList(rules: CustomRules.self)
        )!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(
            dict: [
                "whitelist_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]injas)"]]
            ],
            initialConfig: initialConfig
        )

        // Addition
        validateNewConfigDoesntHitCache(
            dict: [
                "whitelist_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]injas)"], "rule2": ["regex": "([k,K]ittens)"]]
            ],
            initialConfig: initialConfig
        )

        // Removal
        validateNewConfigDoesntHitCache(dict: ["whitelist_rules": ["custom_rules"]], initialConfig: initialConfig)
    }

    func testDisabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(dict: ["disabled_rules": ["nesting"]])!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(dict: ["disabled_rules": ["todo"]], initialConfig: initialConfig)
        // Addition
        validateNewConfigDoesntHitCache(dict: ["disabled_rules": ["nesting", "todo"]], initialConfig: initialConfig)
        // Removal
        validateNewConfigDoesntHitCache(dict: ["disabled_rules": []], initialConfig: initialConfig)
    }

    func testOptInRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(dict: ["opt_in_rules": ["attributes"]])!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(dict: ["opt_in_rules": ["empty_count"]], initialConfig: initialConfig)
        // Aules addition
        validateNewConfigDoesntHitCache(dict: ["opt_in_rules": ["attributes", "empty_count"]],
                                        initialConfig: initialConfig)
        // Removal
        validateNewConfigDoesntHitCache(dict: ["opt_in_rules": []], initialConfig: initialConfig)
    }

    func testEnabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(dict: ["enabled_rules": ["attributes"]])!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(dict: ["enabled_rules": ["empty_count"]], initialConfig: initialConfig)
        // Addition
        validateNewConfigDoesntHitCache(dict: ["enabled_rules": ["attributes", "empty_count"]],
                                        initialConfig: initialConfig)
        // Removal
        validateNewConfigDoesntHitCache(dict: ["enabled_rules": []], initialConfig: initialConfig)
    }

    func testWhitelistRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(dict: ["whitelist_rules": ["nesting"]])!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(dict: ["whitelist_rules": ["todo"]], initialConfig: initialConfig)
        // Addition
        validateNewConfigDoesntHitCache(dict: ["whitelist_rules": ["nesting", "todo"]], initialConfig: initialConfig)
        // Removal
        validateNewConfigDoesntHitCache(dict: ["whitelist_rules": []], initialConfig: initialConfig)
    }

    func testRuleConfigurationChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() {
        let initialConfig = Configuration(dict: ["line_length": 120])!
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        validateNewConfigDoesntHitCache(dict: ["line_length": 100], initialConfig: initialConfig)
        // Addition
        validateNewConfigDoesntHitCache(dict: ["line_length": 100, "number_separator": ["minimum_length": 5]],
                                        initialConfig: initialConfig)
        // Removal
        validateNewConfigDoesntHitCache(dict: [:], initialConfig: initialConfig)
    }
}
