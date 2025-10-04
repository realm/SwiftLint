import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintFramework

// swiftlint:disable file_length

private let optInRules = RuleRegistry.shared.list.list.filter({ $0.1.init() is any OptInRule }).map(\.0)

extension FileSystemAccessTestSuite.ConfigurationTests { // swiftlint:disable:this type_body_length
    @Test
    func basicInit() throws {
        _ = try Configuration(dict: [:])
        _ = try Configuration(dict: ["a": 1, "b": 2])
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.emptyFolder)
    func useDefaultIfNoConfiguration() {
        #expect(Configuration(configurationFiles: []) == Configuration.default)
    }

    @Test
    func emptyConfiguration() {
        guard let config = try? Configuration(dict: [:]) else {
            Issue.record("empty YAML string should yield non-nil Configuration")
            return
        }
        #expect(config.rulesWrapper.disabledRuleIdentifiers.isEmpty)
        #expect(config.includedPaths.isEmpty)
        #expect(config.excludedPaths.isEmpty)
        #expect(config.indentation == .spaces(count: 4))
        #expect(config.reporter == "xcode")
        #expect(reporterFrom(identifier: config.reporter).identifier == "xcode")
        #expect(!config.allowZeroLintableFiles)
        #expect(!config.strict)
        #expect(!config.lenient)
        #expect(config.baseline == nil)
        #expect(config.writeBaseline == nil)
        #expect(!config.checkForUpdates)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func initWithRelativePathAndRootPath() {
        let expectedConfig = Constants.Config._0

        let config = Configuration(configurationFiles: [".swiftlint.yml"])

        #expect(config.rulesWrapper.disabledRuleIdentifiers == expectedConfig.rulesWrapper.disabledRuleIdentifiers)
        #expect(config.includedPaths == expectedConfig.includedPaths)
        #expect(config.excludedPaths == expectedConfig.excludedPaths)
        #expect(config.indentation == expectedConfig.indentation)
        #expect(config.reporter == expectedConfig.reporter)
        #expect(config.allowZeroLintableFiles)
        #expect(config.strict)
        #expect(config.baseline != nil)
        #expect(config.writeBaseline != nil)
    }

    @Test
    func enableAllRulesConfiguration() throws {
        let configuration = try Configuration(
            dict: [:],
            enableAllRules: true,
            cachePath: nil
        )

        #expect(configuration.rules.count == RuleRegistry.shared.list.list.count)
    }

    @Test
    func onlyRule() throws {
        let configuration = try Configuration(
            dict: [:],
            onlyRule: ["nesting"],
            cachePath: nil
        )

        #expect(configuration.rules.count == 1)
    }

    @Test
    func onlyRuleMultiple() throws {
        let onlyRuleIdentifiers = ["nesting", "todo"].sorted()
        let configuration = try Configuration(
            dict: ["only_rules": "line_length"],
            onlyRule: onlyRuleIdentifiers,
            cachePath: nil
        )
        #expect(onlyRuleIdentifiers == configuration.enabledRuleIdentifiers)

        let childConfiguration = try Configuration(dict: ["disabled_rules": onlyRuleIdentifiers.last ?? ""])
        let mergedConfiguration = configuration.merged(withChild: childConfiguration)
        #expect(onlyRuleIdentifiers.dropLast() == mergedConfiguration.enabledRuleIdentifiers)
    }

    @Test
    func onlyRules() throws {
        let only = ["nesting", "todo"]

        let config = try Configuration(dict: ["only_rules": only])
        let configuredIdentifiers = config.rules.map {
            type(of: $0).identifier
        }.sorted()
        #expect(only == configuredIdentifiers)
    }

    @Test
    func onlyRulesWithCustomRules() throws {
        // All custom rules from a config file should be active if the `custom_rules` is included in the `only_rules`
        // As the behavior is different for custom rules from parent configs, this test is helpful
        let only = ["custom_rules"]
        let customRuleIdentifier = "my_custom_rule"
        let customRules = [customRuleIdentifier: ["name": "A name for this custom rule", "regex": "this is illegal"]]

        let config = try Configuration(dict: ["only_rules": only, "custom_rules": customRules])
        guard let resultingCustomRules = config.rules.customRules else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(
            resultingCustomRules.configuration.customRuleConfigurations.contains {
                $0.identifier == customRuleIdentifier
            }
        )
    }

    @Test
    func onlyRulesWithSpecificCustomRules() throws {
        // Individual custom rules can be specified on the command line without specifying `custom_rules` as well.
        let customRuleIdentifier = "my_custom_rule"
        let customRuleIdentifier2 = "my_custom_rule2"
        let only = ["custom_rules"]
        let customRules = [
            customRuleIdentifier: ["name": "A custom rule", "regex": "this is illegal"],
            customRuleIdentifier2: ["name": "Another custom rule", "regex": "this is also illegal"],
        ]

        let configuration = try Configuration(
            dict: [
                "only_rules": only,
                "custom_rules": customRules,
            ],
            onlyRule: [customRuleIdentifier]
        )
        let resultingCustomRules = configuration.rules.customRules
        #expect(resultingCustomRules != nil)

        let enabledCustomRuleIdentifiers =
            resultingCustomRules?.configuration.customRuleConfigurations.map { rule in
                rule.identifier
            }
        #expect(enabledCustomRuleIdentifiers == [customRuleIdentifier])
    }

    @Test
    func warningThreshold_value() throws {
        let config = try Configuration(dict: ["warning_threshold": 5])
        #expect(config.warningThreshold == 5)
    }

    @Test
    func warningThreshold_nil() throws {
        let config = try Configuration(dict: [:])
        #expect(config.warningThreshold == nil)
    }

    @Test
    func otherRuleConfigurationsAlongsideOnlyRules() {
        let only = ["nesting", "todo"]
        let enabledRulesConfigDict = [
            "opt_in_rules": ["line_length"],
            "only_rules": only,
        ]
        let disabledRulesConfigDict = [
            "disabled_rules": ["identifier_name"],
            "only_rules": only,
        ]
        let combinedRulesConfigDict = enabledRulesConfigDict.reduce(into: disabledRulesConfigDict) { $0[$1.0] = $1.1 }
        var configuration = try? Configuration(dict: enabledRulesConfigDict)
        #expect(configuration == nil)
        configuration = try? Configuration(dict: disabledRulesConfigDict)
        #expect(configuration == nil)
        configuration = try? Configuration(dict: combinedRulesConfigDict)
        #expect(configuration == nil)
    }

    @Test
    func disabledRules() throws {
        let disabledConfig = try Configuration(dict: ["disabled_rules": ["nesting", "todo"]])
        #expect(disabledConfig.rulesWrapper.disabledRuleIdentifiers == ["nesting", "todo"],
                       "initializing Configuration with valid rules in Dictionary should succeed")
        let expectedIdentifiers = Set(RuleRegistry.shared.list.list.keys
            .filter({ !(["nesting", "todo"] + optInRules).contains($0) }))
        let configuredIdentifiers = Set(disabledConfig.rules.map {
            type(of: $0).identifier
        })
        #expect(expectedIdentifiers == configuredIdentifiers)
    }

    @Test
    func disabledRulesWithUnknownRule() throws {
        let validRule = "nesting"
        let bogusRule = "no_sprites_with_elf_shoes"

        let configuration = try Configuration(dict: ["disabled_rules": [validRule, bogusRule]])

        #expect(configuration.rulesWrapper.disabledRuleIdentifiers == [validRule],
                       "initializing Configuration with valid rules in YAML string should succeed")
        let expectedIdentifiers = Set(RuleRegistry.shared.list.list.keys
            .filter({ !([validRule] + optInRules).contains($0) }))
        #expect(expectedIdentifiers == Set(configuration.enabledRuleIdentifiers))
    }

    @Test
    func duplicatedRules() {
        let duplicateConfig1 = try? Configuration(dict: ["only_rules": ["todo", "todo"]])
        #expect(
            duplicateConfig1?.rules.count == 1, "duplicate rules should be removed when initializing Configuration"
        )

        let duplicateConfig2 = try? Configuration(dict: ["opt_in_rules": [optInRules.first!, optInRules.first!]])
        #expect(
            duplicateConfig2?.rules.filter { type(of: $0).identifier == optInRules.first! }.count == 1,
            "duplicate rules should be removed when initializing Configuration"
        )

        let duplicateConfig3 = try? Configuration(dict: ["disabled_rules": ["todo", "todo"]])
        #expect(
            duplicateConfig3?.rulesWrapper.disabledRuleIdentifiers.count == 1,
            "duplicate rules should be removed when initializing Configuration"
        )
    }

    @Test(.disabled(if: isRunningWithBazel))
    @WorkingDirectory(path: Constants.Dir.level1)
    func includedExcludedRelativeLocationLevel1() {
        // The included path "File.swift" should be put relative to the configuration file
        // (~> Resources/ProjectMock/File.swift) and not relative to the path where
        // SwiftLint is run from (~> Resources/ProjectMock/Level1/File.swift)
        let configuration = Configuration(configurationFiles: ["../custom_included_excluded.yml"])
        let actualIncludedPath = configuration.includedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredIncludedPath = "File1.swift".absolutePathRepresentation(rootDirectory: Constants.Dir.level0)
        let actualExcludedPath = configuration.excludedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredExcludedPath = "File2.swift".absolutePathRepresentation(rootDirectory: Constants.Dir.level0)

        #expect(actualIncludedPath == desiredIncludedPath)
        #expect(actualExcludedPath == desiredExcludedPath)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func includedExcludedRelativeLocationLevel0() {
        // Same as testIncludedPathRelatedToConfigurationFileLocationLevel1(),
        // but run from the directory the config file resides in
        let configuration = Configuration(configurationFiles: ["custom_included_excluded.yml"])
        let actualIncludedPath = configuration.includedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredIncludedPath = "File1.swift".absolutePathRepresentation(rootDirectory: Constants.Dir.level0)
        let actualExcludedPath = configuration.excludedPaths.first!.bridge()
            .absolutePathRepresentation(rootDirectory: configuration.rootDirectory)
        let desiredExcludedPath = "File2.swift".absolutePathRepresentation(rootDirectory: Constants.Dir.level0)

        #expect(actualIncludedPath == desiredIncludedPath)
        #expect(actualExcludedPath == desiredExcludedPath)
    }

    private class TestFileManager: LintableFileManager {
        func filesToLint(inPath path: String, rootDirectory _: String? = nil) -> [String] {
            var filesToLint: [String] = []
            switch path {
            case "directory": filesToLint = [
                "directory/File1.swift",
                "directory/File2.swift",
                "directory/excluded/Excluded.swift",
                "directory/ExcludedFile.swift",
            ]
            case "directory/excluded": filesToLint = ["directory/excluded/Excluded.swift"]
            case "directory/ExcludedFile.swift": filesToLint = ["directory/ExcludedFile.swift"]
            default: Issue.record("Should not be called with path \(path)")
            }
            return filesToLint.absolutePathsStandardized()
        }

        func modificationDate(forFileAtPath _: String) -> Date? {
            nil
        }

        func isFile(atPath path: String) -> Bool {
            path.hasSuffix(".swift")
        }
    }

    @Test
    func excludedPaths() {
        let fileManager = TestFileManager()
        let configuration = Configuration(
            includedPaths: ["directory"],
            excludedPaths: ["directory/excluded", "directory/ExcludedFile.swift"]
        )

        let excludedPaths = configuration.excludedPaths(fileManager: fileManager)
        let paths = configuration.lintablePaths(inPath: "",
                                                forceExclude: false,
                                                excludeBy: .paths(excludedPaths: excludedPaths),
                                                fileManager: fileManager)
        #expect(["directory/File1.swift", "directory/File2.swift"].absolutePathsStandardized() == paths)
    }

    @Test
    func forceExcludesFile() {
        let fileManager = TestFileManager()
        let configuration = Configuration(excludedPaths: ["directory/ExcludedFile.swift"])
        let excludedPaths = configuration.excludedPaths(fileManager: fileManager)
        let paths = configuration.lintablePaths(inPath: "directory/ExcludedFile.swift",
                                                forceExclude: true,
                                                excludeBy: .paths(excludedPaths: excludedPaths),
                                                fileManager: fileManager)
        #expect([] == paths)
    }

    @Test
    func forceExcludesFileNotPresentInExcluded() {
        let fileManager = TestFileManager()
        let configuration = Configuration(includedPaths: ["directory"],
                                          excludedPaths: ["directory/ExcludedFile.swift", "directory/excluded"])
        let excludedPaths = configuration.excludedPaths(fileManager: fileManager)
        let paths = configuration.lintablePaths(inPath: "",
                                                forceExclude: true,
                                                excludeBy: .paths(excludedPaths: excludedPaths),
                                                fileManager: fileManager)
        #expect(["directory/File1.swift", "directory/File2.swift"].absolutePathsStandardized() == paths)
    }

    @Test
    func forceExcludesDirectory() {
        let fileManager = TestFileManager()
        let configuration = Configuration(excludedPaths: ["directory/excluded", "directory/ExcludedFile.swift"])
        let excludedPaths = configuration.excludedPaths(fileManager: fileManager)
        let paths = configuration.lintablePaths(inPath: "directory",
                                                forceExclude: true,
                                                excludeBy: .paths(excludedPaths: excludedPaths),
                                                fileManager: fileManager)
        #expect(["directory/File1.swift", "directory/File2.swift"].absolutePathsStandardized() == paths)
    }

    @Test
    func forceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre() {
        let fileManager = TestFileManager()
        let configuration = Configuration(excludedPaths: ["directory/excluded", "directory/ExcludedFile.swift"])
        let excludedPaths = configuration.excludedPaths(fileManager: fileManager)
        let paths = configuration.lintablePaths(inPath: "directory",
                                                forceExclude: true,
                                                excludeBy: .paths(excludedPaths: excludedPaths),
                                                fileManager: fileManager)
        #expect(["directory/File1.swift", "directory/File2.swift"].absolutePathsStandardized() == paths)
    }

    @Test
    func lintablePaths() {
        let excluded = Configuration.default.excludedPaths(fileManager: TestFileManager())
        let paths = Configuration.default.lintablePaths(inPath: Constants.Dir.level0,
                                                        forceExclude: false,
                                                        excludeBy: .paths(excludedPaths: excluded))
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = [
            "DirectoryLevel1.swift",
            "Level0.swift", "Level1.swift", "Level2.swift", "Level3.swift",
            "Main.swift", "Sub.swift",
        ]

        #expect(Set(expectedFilenames) == Set(filenames))
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func globIncludePaths() {
        let configuration = Configuration(includedPaths: ["**/Level2"])
        let paths = configuration.lintablePaths(inPath: Constants.Dir.level0,
                                                forceExclude: true,
                                                excludeBy: .paths(excludedPaths: configuration.excludedPaths))
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        let expectedFilenames = ["Level2.swift", "Level3.swift"]

        #expect(Set(expectedFilenames) == Set(filenames))
    }

    @Test
    func globExcludePaths() {
        let configuration = Configuration(
            includedPaths: [Constants.Dir.level3],
            excludedPaths: [Constants.Dir.level3.stringByAppendingPathComponent("*.swift")]
        )

        let excludedPaths = configuration.excludedPaths()
        let lintablePaths = configuration.lintablePaths(inPath: "",
                                                        forceExclude: false,
                                                        excludeBy: .paths(excludedPaths: excludedPaths))
        #expect(lintablePaths.isEmpty)
    }

    // MARK: - Testing Configuration Equality

    @Test
    func isEqualTo() {
        #expect(Constants.Config._0 == Constants.Config._0) // swiftlint:disable:this identical_operands
    }

    @Test
    func isNotEqualTo() {
        #expect(Constants.Config._0 != Constants.Config._2)
    }

    // MARK: - Testing Custom Configuration File

    @Test
    func customConfiguration() {
        let file = SwiftLintFile(path: Constants.Swift._0)!
        #expect(Constants.Config._0.configuration(for: file) != Constants.Config._0Custom.configuration(for: file))
    }

    @Test
    func configurationWithSwiftFileAsRoot() {
        let configuration = Configuration(configurationFiles: [Constants.Yml._0])

        let file = SwiftLintFile(path: Constants.Swift._0)!
        #expect(configuration.configuration(for: file) == configuration)
    }

    @Test
    func configurationWithSwiftFileAsRootAndCustomConfiguration() {
        let configuration = Constants.Config._0Custom

        let file = SwiftLintFile(path: Constants.Swift._0)!
        #expect(configuration.configuration(for: file) == configuration)
    }

    // MARK: - Testing custom indentation

    @Test
    func indentationTabs() throws {
        let configuration = try Configuration(dict: ["indentation": "tabs"])
        #expect(configuration.indentation == .tabs)
    }

    @Test
    func indentationSpaces() throws {
        let configuration = try Configuration(dict: ["indentation": 2])
        #expect(configuration.indentation == .spaces(count: 2))
    }

    @Test
    func indentationFallback() throws {
        let configuration = try Configuration(dict: ["indentation": "invalid"])
        #expect(configuration.indentation == .spaces(count: 4))
    }

    // MARK: - Testing Rules from config dictionary

    private static nonisolated(unsafe) let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    @Test
    func configuresCorrectlyFromDict() throws {
        let ruleConfiguration = [1, 2]
        let config = [RuleWithLevelsMock.identifier: ruleConfiguration]
        let rules = try Self.testRuleList.allRulesWrapped(configurationDict: config).map(\.rule)
        #expect(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    @Test
    func configureFallsBackCorrectly() throws {
        let config = [RuleWithLevelsMock.identifier: ["a", "b"]]
        let rules = try Self.testRuleList.allRulesWrapped(configurationDict: config).map(\.rule)
        #expect(rules == [RuleWithLevelsMock()])
    }

    @Test
    func allowZeroLintableFiles() throws {
        let configuration = try Configuration(dict: ["allow_zero_lintable_files": true])
        #expect(configuration.allowZeroLintableFiles)
    }

    @Test
    func strict() throws {
        let configuration = try Configuration(dict: ["strict": true])
        #expect(configuration.strict)
    }

    @Test
    func lenient() throws {
        let configuration = try Configuration(dict: ["lenient": true])
        #expect(configuration.lenient)
    }

    @Test
    func baseline() throws {
        let baselinePath = "Baseline.json"
        let configuration = try Configuration(dict: ["baseline": baselinePath])
        #expect(configuration.baseline == baselinePath)
    }

    @Test
    func writeBaseline() throws {
        let baselinePath = "Baseline.json"
        let configuration = try Configuration(dict: ["write_baseline": baselinePath])
        #expect(configuration.writeBaseline == baselinePath)
    }

    @Test
    func checkForUpdates() throws {
        let configuration = try Configuration(dict: ["check_for_updates": true])
        #expect(configuration.checkForUpdates)
    }
}

// MARK: - ExcludeByPrefix option tests
extension FileSystemAccessTestSuite.ConfigurationTests {
    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func excludeByPrefixExcludedPaths() {
        let configuration = Configuration(
            includedPaths: ["Level1"],
            excludedPaths: ["Level1/Level1.swift", "Level1/Level2/Level3"]
        )
        let paths = configuration.lintablePaths(
            inPath: Constants.Dir.level0,
            forceExclude: false,
            excludeBy: .prefix
        )
        let filenames = paths.map { $0.bridge().lastPathComponent }
        #expect(filenames == ["Level2.swift"])
    }

    @Test
    func excludeByPrefixForceExcludesFile() {
        let configuration = Configuration(excludedPaths: ["Level1/Level2/Level3/Level3.swift"])
        let paths = configuration.lintablePaths(inPath: "Level1/Level2/Level3/Level3.swift",
                                                forceExclude: true,
                                                excludeBy: .prefix)
        #expect(paths.isEmpty)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func excludeByPrefixForceExcludesFileNotPresentInExcluded() {
        let configuration = Configuration(
            includedPaths: ["Level1"],
            excludedPaths: ["Level1/Level1.swift"])
        let paths = configuration.lintablePaths(
            inPath: "Level1",
            forceExclude: true,
            excludeBy: .prefix
        )
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        #expect(["Level2.swift", "Level3.swift"] == filenames)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func excludeByPrefixForceExcludesDirectory() {
        let configuration = Configuration(
            excludedPaths: [
                "Level1/Level2", "Directory.swift", "ChildConfig", "ParentConfig", "NestedConfig"
            ]
        )
        let paths = configuration.lintablePaths(
            inPath: ".",
            forceExclude: true,
            excludeBy: .prefix
        )
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        #expect(["Level0.swift", "Level1.swift"] == filenames)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func excludeByPrefixForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre() {
        let configuration = Configuration(
            excludedPaths: [
                "Level1", "Directory.swift/DirectoryLevel1.swift", "ChildConfig", "ParentConfig", "NestedConfig"
            ]
        )
        let paths = configuration.lintablePaths(
            inPath: ".",
            forceExclude: true,
            excludeBy: .prefix
        )
        let filenames = paths.map { $0.bridge().lastPathComponent }
        #expect(["Level0.swift"] == filenames)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func excludeByPrefixGlobExcludePaths() {
        let configuration = Configuration(
            includedPaths: ["Level1"],
            excludedPaths: ["Level1/*/*.swift", "Level1/*/*/*.swift"])
        let paths = configuration.lintablePaths(
            inPath: "Level1",
            forceExclude: false,
            excludeBy: .prefix
        )
        let filenames = paths.map { $0.bridge().lastPathComponent }.sorted()
        #expect(filenames == ["Level1.swift"])
    }

    @Test
    func dictInitWithCachePath() throws {
        let configuration = try Configuration(
            dict: ["cache_path": "cache/path/1"]
        )

        #expect(configuration.cachePath == "cache/path/1")
    }

    @Test
        func dictInitWithCachePathFromCommandLine() throws {
        let configuration = try Configuration(
            dict: ["cache_path": "cache/path/1"],
            cachePath: "cache/path/2"
        )

        #expect(configuration.cachePath == "cache/path/2")
    }

    @Test
    func mainInitWithCachePath() {
        let configuration = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/1"
        )

        #expect(configuration.cachePath == "cache/path/1")
    }

    // This test demonstrates an existing bug: when the Configuration is obtained from the in-memory cache, the
    // cachePath is not taken into account
    //
    // This issue may not be reproducible under normal execution: the cache is in memory, so when a user changes
    // the cachePath from command line and re-runs swiftlint, cache is not reused leading to the correct behavior
    @Test
    func mainInitWithCachePathAndCachedConfig() {
        let configuration1 = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/1"
        )

        let configuration2 = Configuration(
            configurationFiles: [],
            cachePath: "cache/path/2"
        )

        #expect(configuration1.cachePath == "cache/path/1")
        #expect(configuration2.cachePath == "cache/path/1")
    }
}

private extension Sequence where Element == String {
    func absolutePathsStandardized() -> [String] {
        map { $0.absolutePathStandardized() }
    }
}

private extension Configuration {
    var enabledRuleIdentifiers: [String] {
        rules.map { type(of: $0).identifier }.sorted()
    }
}
