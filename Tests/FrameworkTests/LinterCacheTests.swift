import Foundation
@testable import SwiftLintFramework
import TestHelpers
import Testing

private struct CacheTestHelper {
    fileprivate let configuration: Configuration

    private let ruleList: RuleList
    private let ruleDescription: RuleDescription
    private let cache: LinterCache

    private var fileManager: TestFileManager {
        // swiftlint:disable:next force_cast
        cache.fileManager as! TestFileManager
    }

    fileprivate init(dict: [String: Any], cache: LinterCache) {
        ruleList = RuleList(rules: RuleWithLevelsMock.self)
        ruleDescription = ruleList.list.values.first!.description
        configuration = try! Configuration(dict: dict, ruleList: ruleList) // swiftlint:disable:this force_try
        self.cache = cache
    }

    fileprivate func makeViolations(file: URL) -> [StyleViolation] {
        touch(file: file)
        return [
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .warning,
                           location: Location(file: file, line: 10, character: 2),
                           reason: "Something is not right"),
            StyleViolation(ruleDescription: ruleDescription,
                           severity: .error,
                           location: Location(file: file, line: 5, character: nil),
                           reason: "Something is wrong"),
        ]
    }

    fileprivate func makeConfig(dict: [String: Any]) -> Configuration {
        try! Configuration(dict: dict, ruleList: ruleList) // swiftlint:disable:this force_try
    }

    fileprivate func touch(file: URL) {
        fileManager.stubbedModificationDateByPath[file] = Date()
    }

    fileprivate func remove(file: URL) {
        fileManager.stubbedModificationDateByPath[file] = nil
    }

    fileprivate func fileCount() -> Int {
        fileManager.stubbedModificationDateByPath.count
    }
}

private class TestFileManager: LintableFileManager {
    fileprivate func filesToLint(inPath _: URL,
                                 excluder _: Excluder) -> [URL] {
        []
    }

    fileprivate var stubbedModificationDateByPath = [URL: Date]()

    fileprivate func modificationDate(forFileAtPath path: URL) -> Date? {
        stubbedModificationDateByPath[path]
    }
}

@Suite(.rulesRegistered)
final class LinterCacheTests {
    // MARK: Test Helpers

    private var cache = LinterCache(fileManager: TestFileManager())

    private func makeCacheTestHelper(dict: [String: Any]) -> CacheTestHelper {
        CacheTestHelper(dict: dict, cache: cache)
    }

    private func cacheAndValidate(violations: [StyleViolation],
                                  forFile: URL,
                                  configuration: Configuration,
                                  sourceLocation: SourceLocation = #_sourceLocation) {
        cache.cache(violations: violations, forFile: forFile, configuration: configuration)
        cache = cache.flushed()
        #expect(
            cache.violations(forFile: forFile, configuration: configuration)! == violations,
            sourceLocation: sourceLocation
        )
    }

    private func cacheAndValidateNoViolationsTwoFiles(configuration: Configuration,
                                                      sourceLocation: SourceLocation = #_sourceLocation) {
        let (file1, file2) = ("file1.swift".url(), "file2.swift".url())
        // swiftlint:disable:next force_cast
        let fileManager = cache.fileManager as! TestFileManager
        fileManager.stubbedModificationDateByPath = [file1: Date(), file2: Date()]

        cacheAndValidate(violations: [], forFile: file1, configuration: configuration, sourceLocation: sourceLocation)
        cacheAndValidate(violations: [], forFile: file2, configuration: configuration, sourceLocation: sourceLocation)
    }

    private func validateNewConfigDoesntHitCache(dict: [String: Any],
                                                 initialConfig: Configuration,
                                                 sourceLocation: SourceLocation = #_sourceLocation) throws {
        let (file1, file2) = ("file1.swift".url(), "file2.swift".url())
        let newConfig = try Configuration(dict: dict)

        #expect(
            cache.violations(forFile: file1, configuration: newConfig) == nil,
            sourceLocation: sourceLocation
        )
        #expect(
            cache.violations(forFile: file2, configuration: newConfig) == nil,
            sourceLocation: sourceLocation
        )

        #expect(
            cache.violations(forFile: file1, configuration: initialConfig)!.isEmpty,
            sourceLocation: sourceLocation
        )
        #expect(
            cache.violations(forFile: file2, configuration: initialConfig)!.isEmpty,
            sourceLocation: sourceLocation
        )
    }

    // MARK: Cache Reuse

    // Two subsequent lints with no changes reuses cache
    @Test
    func unchangedFilesReusesCache() {
        let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"]])
        let file = "foo.swift".url()
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        helper.touch(file: file)

        #expect(cache.violations(forFile: file, configuration: helper.configuration) == nil)
    }

    @Test
    func configFileReorderedReusesCache() {
        let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "disabled_rules": [Any]()])
        let file = "foo.swift".url()
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["disabled_rules": [Any](), "only_rules": ["mock"]])
        #expect(cache.violations(forFile: file, configuration: configuration2)! == violations)
    }

    @Test
    func configFileWhitespaceAndCommentsChangedOrAddedOrRemovedReusesCache() throws {
        let helper = makeCacheTestHelper(dict: try YamlParser.parse("only_rules:\n  - mock"))
        let file = "foo.swift".url()
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["disabled_rules": [Any](), "only_rules": ["mock"]])
        #expect(cache.violations(forFile: file, configuration: configuration2)! == violations)
        let configYamlWithComment = try YamlParser.parse("# comment1\nonly_rules:\n  - mock # comment2")
        let configuration3 = helper.makeConfig(dict: configYamlWithComment)
        #expect(cache.violations(forFile: file, configuration: configuration3)! == violations)
        #expect(cache.violations(forFile: file, configuration: helper.configuration)! == violations)
    }

    @Test
    func configFileUnrelatedKeysChangedOrAddedOrRemovedReusesCache() {
        let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
        let file = "foo.swift".url()
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let configuration2 = helper.makeConfig(dict: ["only_rules": ["mock"], "reporter": "xcode"])
        #expect(cache.violations(forFile: file, configuration: configuration2)! == violations)
        let configuration3 = helper.makeConfig(dict: ["only_rules": ["mock"]])
        #expect(cache.violations(forFile: file, configuration: configuration3)! == violations)
    }

    // MARK: Sing-File Cache Invalidation

    // Two subsequent lints with a file touch in between causes just that one
    // file to be re-linted, with the cache used for all other files
    @Test
    func changedFileCausesJustThatFileToBeLintWithCacheUsedForAllOthers() {
        let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
        let (file1, file2) = ("file1.swift".url(), "file2.swift".url())
        let violations1 = helper.makeViolations(file: file1)
        let violations2 = helper.makeViolations(file: file2)

        cacheAndValidate(violations: violations1, forFile: file1, configuration: helper.configuration)
        cacheAndValidate(violations: violations2, forFile: file2, configuration: helper.configuration)
        helper.touch(file: file2)
        #expect(cache.violations(forFile: file1, configuration: helper.configuration)! == violations1)
        #expect(cache.violations(forFile: file2, configuration: helper.configuration) == nil)
    }

    @Test
    func fileRemovedPreservesThatFileInTheCacheAndDoesntCauseAnyOtherFilesToBeLinted() {
        let helper = makeCacheTestHelper(dict: ["only_rules": ["mock"], "reporter": "json"])
        let (file1, file2) = ("file1.swift".url(), "file2.swift".url())
        let violations1 = helper.makeViolations(file: file1)
        let violations2 = helper.makeViolations(file: file2)

        cacheAndValidate(violations: violations1, forFile: file1, configuration: helper.configuration)
        cacheAndValidate(violations: violations2, forFile: file2, configuration: helper.configuration)
        #expect(helper.fileCount() == 2)
        helper.remove(file: file2)
        #expect(cache.violations(forFile: file1, configuration: helper.configuration)! == violations1)
        #expect(helper.fileCount() == 1)
    }

    // MARK: All-File Cache Invalidation

    @Test
    func customRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(
            dict: [
                "only_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]inja)"]],
            ],
            ruleList: RuleList(rules: CustomRules.self)
        )
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(
            dict: [
                "only_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]injas)"]],
            ],
            initialConfig: initialConfig
        )

        // Addition
        try validateNewConfigDoesntHitCache(
            dict: [
                "only_rules": ["custom_rules", "rule1"],
                "custom_rules": ["rule1": ["regex": "([n,N]injas)"], "rule2": ["regex": "([k,K]ittens)"]],
            ],
            initialConfig: initialConfig
        )

        // Removal
        try validateNewConfigDoesntHitCache(dict: ["only_rules": ["custom_rules"]], initialConfig: initialConfig)
    }

    @Test
    func disabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(dict: ["disabled_rules": ["nesting"]])
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(dict: ["disabled_rules": ["todo"]], initialConfig: initialConfig)
        // Addition
        try validateNewConfigDoesntHitCache(dict: ["disabled_rules": ["nesting", "todo"]], initialConfig: initialConfig)
        // Removal
        try validateNewConfigDoesntHitCache(dict: ["disabled_rules": [Any]()], initialConfig: initialConfig)
    }

    @Test
    func optInRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(dict: ["opt_in_rules": ["attributes"]])
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(dict: ["opt_in_rules": ["empty_count"]], initialConfig: initialConfig)
        // Rules addition
        try validateNewConfigDoesntHitCache(dict: ["opt_in_rules": ["attributes", "empty_count"]],
                                            initialConfig: initialConfig)
        // Removal
        try validateNewConfigDoesntHitCache(dict: ["opt_in_rules": [Any]()], initialConfig: initialConfig)
    }

    @Test
    func enabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(dict: ["enabled_rules": ["attributes"]])
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(dict: ["enabled_rules": ["empty_count"]], initialConfig: initialConfig)
        // Addition
        try validateNewConfigDoesntHitCache(dict: ["enabled_rules": ["attributes", "empty_count"]],
                                            initialConfig: initialConfig)
        // Removal
        try validateNewConfigDoesntHitCache(dict: ["enabled_rules": [Any]()], initialConfig: initialConfig)
    }

    @Test
    func onlyRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(dict: ["only_rules": ["nesting"]])
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(dict: ["only_rules": ["todo"]], initialConfig: initialConfig)
        // Addition
        try validateNewConfigDoesntHitCache(dict: ["only_rules": ["nesting", "todo"]], initialConfig: initialConfig)
        // Removal
        try validateNewConfigDoesntHitCache(dict: ["only_rules": [Any]()], initialConfig: initialConfig)
    }

    @Test
    func ruleConfigurationChangedOrAddedOrRemovedCausesAllFilesToBeReLinted() throws {
        let initialConfig = try Configuration(dict: ["line_length": 120])
        cacheAndValidateNoViolationsTwoFiles(configuration: initialConfig)

        // Change
        try validateNewConfigDoesntHitCache(dict: ["line_length": 100], initialConfig: initialConfig)
        // Addition
        try validateNewConfigDoesntHitCache(dict: ["line_length": 100, "number_separator": ["minimum_length": 5]],
                                            initialConfig: initialConfig)
        // Removal
        try validateNewConfigDoesntHitCache(dict: [:], initialConfig: initialConfig)
    }

    @Test
    func swiftVersionChangedRemovedCausesAllFilesToBeReLinted() {
        let fileManager = TestFileManager()
        cache = LinterCache(fileManager: fileManager)
        let helper = makeCacheTestHelper(dict: [:])
        let file = "foo.swift".url()
        let violations = helper.makeViolations(file: file)

        cacheAndValidate(violations: violations, forFile: file, configuration: helper.configuration)
        let thisSwiftVersionCache = cache

        let differentSwiftVersion: SwiftVersion = .five
        cache = LinterCache(fileManager: fileManager, swiftVersion: differentSwiftVersion)

        #expect(thisSwiftVersionCache.violations(forFile: file, configuration: helper.configuration) != nil)
        #expect(cache.violations(forFile: file, configuration: helper.configuration) == nil)
    }
}
