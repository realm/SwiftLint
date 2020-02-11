import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private let optInRules = masterRuleList.list.filter({ $0.1.init() is OptInRule }).map({ $0.0 })

class ConfigurationTests: XCTestCase, ProjectMock {
    func testInit() {
        XCTAssert((try? Configuration(dict: [:])) != nil,
                  "initializing Configuration with empty Dictionary should succeed")
        XCTAssert((try? Configuration(dict: ["a": 1, "b": 2])) != nil,
                  "initializing Configuration with valid Dictionary should succeed")
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
        let previousWorkingDir = FileManager.default.currentDirectoryPath
        let rootPath = projectMockSwift0
        let expectedConfig = projectMockConfig0
        FileManager.default.changeCurrentDirectoryPath(projectMockPathLevel0)

        let config = Configuration(
            configurationFiles: [".swiftlint.yml"],
            rootPath: rootPath,
            optional: false,
            quiet: true
        )

        XCTAssertEqual(config.rulesWrapper.disabledRuleIdentifiers, expectedConfig.rulesWrapper.disabledRuleIdentifiers)
        XCTAssertEqual(config.includedPaths, expectedConfig.includedPaths)
        XCTAssertEqual(config.excludedPaths, expectedConfig.excludedPaths)
        XCTAssertEqual(config.indentation, expectedConfig.indentation)
        XCTAssertEqual(config.reporter, expectedConfig.reporter)
        XCTAssertTrue(config.allowZeroLintableFiles)

        FileManager.default.changeCurrentDirectoryPath(previousWorkingDir)
    }

    func testEnableAllRulesConfiguration() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(
            dict: [:], ruleList: masterRuleList,
            enableAllRules: true, cachePath: nil
        )

        XCTAssertEqual(configuration.rules.count, masterRuleList.list.count)
    }

    func testWhitelistRules() {
        let whitelist = ["nesting", "todo"]

        // swiftlint:disable:next force_try
        let config = try! Configuration(dict: ["whitelist_rules": whitelist])
        let configuredIdentifiers = config.rules.map {
            type(of: $0).description.identifier
        }.sorted()
        XCTAssertEqual(whitelist, configuredIdentifiers)
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

        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["disabled_rules": [validRule, bogusRule]])

        XCTAssertEqual(configuration.rulesWrapper.disabledRuleIdentifiers,
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
        let duplicateConfig1 = try? Configuration(dict: ["whitelist_rules": ["todo", "todo"]])
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
        let paths = Configuration.default.lintablePaths(inPath: projectMockPathLevel0, forceExclude: false)
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = [
            "DirectoryLevel1.swift",
            "Level0.swift", "Level1.swift", "Level2.swift", "Level3.swift",
            "Valid1.swift", "Valid2.swift", "Main.swift", "Sub.swift"
        ]

        XCTAssertEqual(Set(expectedFilenames), Set(filenames))
    }

    func testGlobExcludePaths() {
        let configuration = Configuration(
            includedPaths: [projectMockPathLevel3],
            excludedPaths: [projectMockPathLevel3.stringByAppendingPathComponent("*.swift")]
        )

        XCTAssertEqual(configuration.lintablePaths(inPath: "", forceExclude: false), [])
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
        let file = SwiftLintFile(path: projectMockSwift0)!
        XCTAssertNotEqual(projectMockConfig0.configuration(for: file),
                          projectMockConfig0CustomPath.configuration(for: file))
    }

    func testConfigurationWithSwiftFileAsRoot() {
        let configuration = Configuration(
            configurationFiles: [projectMockYAML0],
            rootPath: projectMockSwift0,
            optional: false,
            quiet: true
        )

        let file = SwiftLintFile(path: projectMockSwift0)!
        XCTAssertEqual(configuration.configuration(for: file), configuration)
    }

    func testConfigurationWithSwiftFileAsRootAndCustomConfiguration() {
        let configuration = Configuration(
            configurationFiles: [projectMockYAML0CustomPath],
            rootPath: projectMockSwift0,
            optional: false,
            quiet: true
        )

        let file = SwiftLintFile(path: projectMockSwift0)!
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

    let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

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
