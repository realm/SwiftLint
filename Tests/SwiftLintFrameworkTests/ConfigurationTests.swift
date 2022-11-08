import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

// swiftlint:disable file_length type_body_length

private let optInRules = RuleRegistry.shared.list.list.filter({ $0.1.init() is OptInRule }).map({ $0.0 })

class ConfigurationTests: SwiftLintTestCase {
    // MARK: Setup & Teardown
    private var previousWorkingDir: String!

    override func setUp() {
        super.setUp()
        Configuration.resetCache()
        previousWorkingDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
    }

    override func tearDown() {
        super.tearDown()
        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    // MARK: Tests
    func testInit() {
        XCTAssert((try? Configuration(dict: [:])) != nil,
                  "initializing Configuration with empty Dictionary should succeed")
        XCTAssert((try? Configuration(dict: ["a": 1, "b": 2])) != nil,
                  "initializing Configuration with valid Dictionary should succeed")
    }

    func testNoConfiguration() {
        // Change to a folder where there is no `.swiftlint.yml`
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.emptyFolder)

        // Test whether the default configuration is used if there is no `.swiftlint.yml` or other config file
        XCTAssertEqual(Configuration(configurationFiles: []), Configuration.default)
    }

    func testEmptyConfiguration() {
        guard let config = try? Configuration(dict: [:]) else {
            XCTFail("empty YAML string should yield non-nil Configuration")
            return
        }
        XCTAssertEqual(config.rulesWrapper.disabledRuleIdentifiers, [])
        XCTAssertEqual(config.includedPaths, [])
        XCTAssertEqual(config.excludedPaths, [])
        XCTAssertEqual(config.indentation, .spaces(count: 4))
        XCTAssertEqual(config.reporter, "xcode")
        XCTAssertEqual(reporterFrom(identifier: config.reporter).identifier, "xcode")
        XCTAssertFalse(config.allowZeroLintableFiles)
    }

    func testInitWithRelativePathAndRootPath() {
        let expectedConfig = Mock.Config._0

        let config = Configuration(configurationFiles: [".swiftlint.yml"])

        XCTAssertEqual(config.rulesWrapper.disabledRuleIdentifiers, expectedConfig.rulesWrapper.disabledRuleIdentifiers)
        XCTAssertEqual(config.includedPaths, expectedConfig.includedPaths)
        XCTAssertEqual(config.excludedPaths, expectedConfig.excludedPaths)
        XCTAssertEqual(config.indentation, expectedConfig.indentation)
        XCTAssertEqual(config.reporter, expectedConfig.reporter)
        XCTAssertTrue(config.allowZeroLintableFiles)
    }

    func testEnableAllRulesConfiguration() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(
            dict: [:],
            ruleList: RuleRegistry.shared.list,
            enableAllRules: true,
            cachePath: nil
        )

        XCTAssertEqual(configuration.rules.count, RuleRegistry.shared.list.list.count)
    }

    func testOnlyRules() {
        let only = ["nesting", "todo"]

        // swiftlint:disable:next force_try
        let config = try! Configuration(dict: ["only_rules": only])
        let configuredIdentifiers = config.rules.map {
            type(of: $0).description.identifier
        }.sorted()
        XCTAssertEqual(only, configuredIdentifiers)
    }

    func testOnlyRulesWithCustomRules() {
        // All custom rules from a config file should be active if the `custom_rules` is included in the `only_rules`
        // As the behavior is different for custom rules from parent configs, this test is helpful
        let only = ["custom_rules"]
        let customRuleIdentifier = "my_custom_rule"
        let customRules = [customRuleIdentifier: ["name": "A name for this custom rule", "regex": "this is illegal"]]

        // swiftlint:disable:next force_try
        let config = try! Configuration(dict: ["only_rules": only, "custom_rules": customRules])
        guard let resultingCustomRules = config.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertTrue(
            resultingCustomRules.configuration.customRuleConfigurations.contains {
                $0.identifier == customRuleIdentifier
            }
        )
    }

    func testWarningThreshold_value() {
        // swiftlint:disable:next force_try
        let config = try! Configuration(dict: ["warning_threshold": 5])
        XCTAssertEqual(config.warningThreshold, 5)
    }

    func testWarningThreshold_nil() {
        // swiftlint:disable:next force_try
        let config = try! Configuration(dict: [:])
        XCTAssertNil(config.warningThreshold)
    }

    func testOtherRuleConfigurationsAlongsideOnlyRules() {
        let only = ["nesting", "todo"]
        let enabledRulesConfigDict = [
            "opt_in_rules": ["line_length"],
            "only_rules": only
        ]
        let disabledRulesConfigDict = [
            "disabled_rules": ["identifier_name"],
            "only_rules": only
        ]
        let combinedRulesConfigDict = enabledRulesConfigDict.reduce(into: disabledRulesConfigDict) { $0[$1.0] = $1.1 }
        var configuration = try? Configuration(dict: enabledRulesConfigDict)
        XCTAssertNil(configuration)
        configuration = try? Configuration(dict: disabledRulesConfigDict)
        XCTAssertNil(configuration)
        configuration = try? Configuration(dict: combinedRulesConfigDict)
        XCTAssertNil(configuration)
    }

    func testDisabledRules() {
        // swiftlint:disable:next force_try
        let disabledConfig = try! Configuration(dict: ["disabled_rules": ["nesting", "todo"]])
        XCTAssertEqual(disabledConfig.rulesWrapper.disabledRuleIdentifiers,
                       ["nesting", "todo"],
                       "initializing Configuration with valid rules in Dictionary should succeed")
        let expectedIdentifiers = Set(RuleRegistry.shared.list.list.keys
            .filter({ !(["nesting", "todo"] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(disabledConfig.rules.map {
            type(of: $0).description.identifier
        })
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    func testDisabledRulesWithUnknownRule() {
        let validRule = "nesting"
        let bogusRule = "no_sprites_with_elf_shoes"

        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["disabled_rules": [validRule, bogusRule]])

        XCTAssertEqual(configuration.rulesWrapper.disabledRuleIdentifiers,
                       [validRule],
                       "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Set(RuleRegistry.shared.list.list.keys
            .filter({ !([validRule] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(configuration.rules.map {
            type(of: $0).description.identifier
        })
        XCTAssertEqual(expectedIdentifiers, configuredIdentifiers)
    }

    func testDuplicatedRules() {
        let duplicateConfig1 = try? Configuration(dict: ["only_rules": ["todo", "todo"]])
        XCTAssertEqual(
            duplicateConfig1?.rules.count, 1, "duplicate rules should be removed when initializing Configuration"
        )

        let duplicateConfig2 = try? Configuration(dict: ["opt_in_rules": [optInRules.first!, optInRules.first!]])
        XCTAssertEqual(
            duplicateConfig2?.rules.filter { type(of: $0).description.identifier == optInRules.first! }.count, 1,
            "duplicate rules should be removed when initializing Configuration"
        )

        let duplicateConfig3 = try? Configuration(dict: ["disabled_rules": ["todo", "todo"]])
        XCTAssertEqual(
            duplicateConfig3?.rulesWrapper.disabledRuleIdentifiers.count, 1,
            "duplicate rules should be removed when initializing Configuration"
        )
    }

    func testIncludedExcludedRelativeLocationLevel1() {
        guard !isRunningWithBazel else {
            return
        }

        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level1)

        // The included path "File.swift" should be put relative to the configuration file
        // (~> Resources/ProjectMock/File.swift) and not relative to the path where
        // SwiftLint is run from (~> Resources/ProjectMock/Level1/File.swift)
        let configuration = Configuration(configurationFiles: ["../custom_included_excluded.yml"])
        let actualIncludedPath = configuration.includedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredIncludedPath = "File1.swift".absolutePathRepresentation(rootDirectory: Mock.Dir.level0)
        let actualExcludedPath = configuration.excludedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredExcludedPath = "File2.swift".absolutePathRepresentation(rootDirectory: Mock.Dir.level0)

        XCTAssertEqual(actualIncludedPath, desiredIncludedPath)
        XCTAssertEqual(actualExcludedPath, desiredExcludedPath)
    }

    func testIncludedExcludedRelativeLocationLevel0() {
        // Same as testIncludedPathRelatedToConfigurationFileLocationLevel1(),
        // but run from the directory the config file resides in
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(configurationFiles: ["custom_included_excluded.yml"])
        let actualIncludedPath = configuration.includedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredIncludedPath = "File1.swift".absolutePathRepresentation(rootDirectory: Mock.Dir.level0)
        let actualExcludedPath = configuration.excludedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredExcludedPath = "File2.swift".absolutePathRepresentation(rootDirectory: Mock.Dir.level0)

        XCTAssertEqual(actualIncludedPath, desiredIncludedPath)
        XCTAssertEqual(actualExcludedPath, desiredExcludedPath)
    }

    private class TestFileManager: LintableFileManager {
        func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
            switch path {
            case "directory": return ["directory/File1.swift", "directory/File2.swift",
                                      "directory/excluded/Excluded.swift",
                                      "directory/ExcludedFile.swift"]
            case "directory/excluded": return ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift": return ["directory/ExcludedFile.swift"]
            default: break
            }
            XCTFail("Should not be called with path \(path)")
            return []
        }

        func modificationDate(forFileAtPath path: String) -> Date? {
            return nil
        }
    }

    func testExcludedPaths() {
        let configuration = Configuration(includedPaths: ["directory"],
                                          excludedPaths: ["directory/excluded",
                                                          "directory/ExcludedFile.swift"])
        let paths = configuration.lintablePaths(inPath: "", forceExclude: false, fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesFile() {
        let configuration = Configuration(excludedPaths: ["directory/ExcludedFile.swift"])
        let paths = configuration.lintablePaths(inPath: "directory/ExcludedFile.swift", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual([], paths)
    }

    func testForceExcludesFileNotPresentInExcluded() {
        let configuration = Configuration(includedPaths: ["directory"],
                                          excludedPaths: ["directory/ExcludedFile.swift", "directory/excluded"])
        let paths = configuration.lintablePaths(inPath: "", forceExclude: true, fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesDirectory() {
        let configuration = Configuration(excludedPaths: ["directory/excluded", "directory/ExcludedFile.swift"])
        let paths = configuration.lintablePaths(inPath: "directory", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre() {
        let configuration = Configuration(excludedPaths: ["directory/excluded", "directory/ExcludedFile.swift"])
        let paths = configuration.lintablePaths(inPath: "directory", forceExclude: true,
                                                fileManager: TestFileManager())
        XCTAssertEqual(["directory/File1.swift", "directory/File2.swift"], paths)
    }

    func testLintablePaths() {
        let paths = Configuration.default.lintablePaths(inPath: Mock.Dir.level0, forceExclude: false)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = [
            "DirectoryLevel1.swift",
            "Level0.swift", "Level1.swift", "Level2.swift", "Level3.swift",
            "Main.swift", "Sub.swift"
        ]

        XCTAssertEqual(Set(expectedFilenames), Set(filenames))
    }

    func testGlobIncludePaths() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(includedPaths: ["**/Level2"])
        let paths = configuration.lintablePaths(inPath: Mock.Dir.level0, forceExclude: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = ["Level2.swift", "Level3.swift"]

        XCTAssertEqual(Set(expectedFilenames), Set(filenames))
    }

    func testGlobExcludePaths() {
        let configuration = Configuration(
            includedPaths: [Mock.Dir.level3],
            excludedPaths: [Mock.Dir.level3.stringByAppendingPathComponent("*.swift")]
        )

        XCTAssertEqual(configuration.lintablePaths(inPath: "", forceExclude: false), [])
    }

    // MARK: - Testing Configuration Equality

    func testIsEqualTo() {
        XCTAssertEqual(Mock.Config._0, Mock.Config._0)
    }

    func testIsNotEqualTo() {
        XCTAssertNotEqual(Mock.Config._0, Mock.Config._2)
    }

    // MARK: - Testing Custom Configuration File

    func testCustomConfiguration() {
        let file = SwiftLintFile(path: Mock.Swift._0)!
        XCTAssertNotEqual(Mock.Config._0.configuration(for: file),
                          Mock.Config._0Custom.configuration(for: file))
    }

    func testConfigurationWithSwiftFileAsRoot() {
        let configuration = Configuration(configurationFiles: [Mock.Yml._0])

        let file = SwiftLintFile(path: Mock.Swift._0)!
        XCTAssertEqual(configuration.configuration(for: file), configuration)
    }

    func testConfigurationWithSwiftFileAsRootAndCustomConfiguration() {
        let configuration = Mock.Config._0Custom

        let file = SwiftLintFile(path: Mock.Swift._0)!
        XCTAssertEqual(configuration.configuration(for: file), configuration)
    }

    // MARK: - Testing custom indentation

    func testIndentationTabs() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["indentation": "tabs"])
        XCTAssertEqual(configuration.indentation, .tabs)
    }

    func testIndentationSpaces() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["indentation": 2])
        XCTAssertEqual(configuration.indentation, .spaces(count: 2))
    }

    func testIndentationFallback() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["indentation": "invalid"])
        XCTAssertEqual(configuration.indentation, .spaces(count: 4))
    }

    // MARK: - Testing Rules from config dictionary

    private let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    func testConfiguresCorrectlyFromDict() throws {
        let ruleConfiguration = [1, 2]
        let config = [RuleWithLevelsMock.description.identifier: ruleConfiguration]
        let rules = try testRuleList.allRulesWrapped(configurationDict: config).map { $0.rule }
        XCTAssertTrue(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    func testConfigureFallsBackCorrectly() throws {
        let config = [RuleWithLevelsMock.description.identifier: ["a", "b"]]
        let rules = try testRuleList.allRulesWrapped(configurationDict: config).map { $0.rule }
        XCTAssertTrue(rules == [RuleWithLevelsMock()])
    }

    func testAllowZeroLintableFiles() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["allow_zero_lintable_files": true])
        XCTAssertTrue(configuration.allowZeroLintableFiles)
    }
}

// MARK: - ExcludeByPrefix option tests
extension ConfigurationTests {
    func testExcludeByPrefixExcludedPaths() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(includedPaths: ["Level1"],
                                          excludedPaths: ["Level1/Level1.swift",
                                                          "Level1/Level2/Level3"])
        let paths = configuration.lintablePaths(inPath: Mock.Dir.level0,
                                                forceExclude: false,
                                                excludeByPrefix: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }
        XCTAssertEqual(filenames, ["Level2.swift"])
    }

    func testExcludeByPrefixForceExcludesFile() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(excludedPaths: ["Level1/Level2/Level3/Level3.swift"])
        let paths = configuration.lintablePaths(inPath: "Level1/Level2/Level3/Level3.swift",
                                                forceExclude: true,
                                                excludeByPrefix: true)
        XCTAssertEqual([], paths)
    }

    func testExcludeByPrefixForceExcludesFileNotPresentInExcluded() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(includedPaths: ["Level1"],
                                          excludedPaths: ["Level1/Level1.swift"])
        let paths = configuration.lintablePaths(inPath: "Level1",
                                                forceExclude: true,
                                                excludeByPrefix: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        XCTAssertEqual(["Level2.swift", "Level3.swift"], filenames)
    }

    func testExcludeByPrefixForceExcludesDirectory() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(
            excludedPaths: [
                "Level1/Level2", "Directory.swift", "ChildConfig", "ParentConfig", "NestedConfig"
            ]
        )
        let paths = configuration.lintablePaths(inPath: ".",
                                                forceExclude: true,
                                                excludeByPrefix: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        XCTAssertEqual(["Level0.swift", "Level1.swift"], filenames)
    }

    func testExcludeByPrefixForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(
            excludedPaths: [
                "Level1", "Directory.swift/DirectoryLevel1.swift", "ChildConfig", "ParentConfig", "NestedConfig"
            ]
        )
        let paths = configuration.lintablePaths(inPath: ".",
                                                forceExclude: true,
                                                excludeByPrefix: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }
        XCTAssertEqual(["Level0.swift"], filenames)
    }

    func testExcludeByPrefixGlobExcludePaths() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.level0)
        let configuration = Configuration(
            includedPaths: ["Level1"],
            excludedPaths: ["Level1/*/*.swift", "Level1/*/*/*.swift"])
        let paths = configuration.lintablePaths(inPath: "Level1",
                                                forceExclude: false,
                                                excludeByPrefix: true)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        XCTAssertEqual(filenames, ["Level1.swift"])
    }

    func testDictInitWithCachePath() throws {
        let configuration = try Configuration(
            dict: ["cache_path": "cache/path/1"]
        )

        XCTAssertEqual(configuration.cachePath, "cache/path/1")
    }

    func testDictInitWithCachePathFromCommandLine() throws {
        let configuration = try Configuration(
            dict: ["cache_path": "cache/path/1"],
            cachePath: "cache/path/2"
        )

        XCTAssertEqual(configuration.cachePath, "cache/path/2")
    }

    func testMainInitWithCachePath() {
        let configuration = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/1"
        )

        XCTAssertEqual(configuration.cachePath, "cache/path/1")
    }

    // This test demonstrates an existing bug: when the Configuration is obtained from the in-memory cache, the
    // cachePath is not taken into account
    //
    // This issue may not be reproducible under normal execution: the cache is in memory, so when a user changes
    // the cachePath from command line and re-runs swiftlint, cache is not reused leading to the correct behavior
    func testMainInitWithCachePathAndCachedConfig() {
        let configuration1 = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/1"
        )

        let configuration2 = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/2"
        )

        XCTAssertEqual(configuration1.cachePath, "cache/path/1")
        XCTAssertEqual(configuration2.cachePath, "cache/path/1")
    }
}
