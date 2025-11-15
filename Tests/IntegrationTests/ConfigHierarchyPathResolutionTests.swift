import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftLintFramework
import TestHelpers
import XCTest

/// Integration tests for configuration hierarchy path resolution.
/// These tests verify that included/excluded paths are correctly resolved when
/// merging parent/child configs and applying nested configs across different directories.
final class ConfigHierarchyPathResolutionTests: SwiftLintTestCase {
    // MARK: - Setup

    private var fixturesPath: String {
        #filePath.bridge()
            .deletingLastPathComponent
            .stringByAppendingPathComponent("PathHierarchyFixtures")
    }

    private func fixturePath(_ scenario: String) -> String {
        fixturesPath.stringByAppendingPathComponent(scenario)
    }

    // MARK: - Helper Methods

    /// Returns the paths of lintable files relative to the fixture directory
    private func lintableFilePaths(
        in scenario: String,
        configFile: String? = nil,
        inPath: String = ""
    ) -> [String] {
        let scenarioPath = fixturePath(scenario)
        let configFiles = configFile.map { [scenarioPath.stringByAppendingPathComponent($0)] } ?? []
        let config = Configuration(configurationFiles: configFiles)

        let searchPath = inPath.isEmpty ? scenarioPath : scenarioPath.stringByAppendingPathComponent(inPath)
        let files = config.lintableFiles(
            inPath: searchPath,
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths())
        )

        // Convert to relative paths for easier assertions
        return files.map { file in
            file.path!.bridge().path(relativeTo: scenarioPath)
        }.sorted()
    }

    /// Asserts that a file is lintable (included)
    private func assertLintable(
        _ relativePath: String,
        in scenario: String,
        configFile: String? = nil,
        inPath: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let paths = lintableFilePaths(in: scenario, configFile: configFile, inPath: inPath)
        XCTAssertTrue(
            paths.contains(relativePath),
            "Expected \(relativePath) to be lintable. Lintable files: \(paths)",
            file: file,
            line: line
        )
    }

    /// Asserts that a file is not lintable (excluded)
    private func assertNotLintable(
        _ relativePath: String,
        in scenario: String,
        configFile: String? = nil,
        inPath: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let paths = lintableFilePaths(in: scenario, configFile: configFile, inPath: inPath)
        XCTAssertFalse(
            paths.contains(relativePath),
            "Expected \(relativePath) to NOT be lintable. Lintable files: \(paths)",
            file: file,
            line: line
        )
    }

    // MARK: - Parent/Child Config Tests

    func testParentChildSameDirectory() {
        // Parent includes Sources, excludes Sources/Generated
        // Child excludes Sources/Models
        // Expected: Sources/CoreFile.swift included, others excluded

        let paths = lintableFilePaths(in: "scenario1_parent_child_same_dir", configFile: "parent.yml")
        XCTAssertEqual(paths, ["Sources/CoreFile.swift"])
    }

    func testParentChildDifferentDirectories() {
        // Parent in base/ includes ../project/Sources
        // Child in project/ excludes Sources/Generated
        // Expected: Sources/Core/Service.swift included, Sources/Generated/Model.swift excluded

        let paths = lintableFilePaths(
            in: "scenario2_parent_child_different_dirs",
            configFile: "project/.swiftlint.yml",
            inPath: "project"
        )
        XCTAssertEqual(paths, ["project/Sources/Core/Service.swift"])
    }

    func testChildOverridesParentExclusion() {
        // Parent excludes Vendor
        // Child includes Vendor/Critical
        // Expected: Vendor/Critical/Important.swift included, Vendor/Other/Library.swift excluded

        let paths = lintableFilePaths(
            in: "scenario3_child_overrides_parent_exclusion",
            configFile: "project/.swiftlint.yml",
            inPath: "project"
        )
        XCTAssertEqual(paths, ["project/Vendor/Critical/Important.swift"])
    }

    func testParentIncludesChildExcludes() {
        // Verify that child's exclusions are properly applied to parent's inclusions
        let paths = lintableFilePaths(in: "scenario1_parent_child_same_dir", configFile: "parent.yml")
        XCTAssertEqual(paths, ["Sources/CoreFile.swift"])
    }

    // MARK: - Nested Configuration Tests

    func testNestedConfigurationBasic() {
        // Root config includes ModuleA and ModuleB
        // ModuleA has nested config with opt-in rules
        // Note: Nested configs affect rule configuration per-file, NOT file discovery
        // File discovery uses only the root config's included/excluded paths

        let paths = lintableFilePaths(in: "scenario4_nested_basic", configFile: ".swiftlint.yml")
        XCTAssertEqual(paths, [
            "ModuleA/File.swift",
            "ModuleA/Generated/File.swift",
            "ModuleB/File.swift",
        ])
    }

    func testNestedConfigurationAppliesOnlyToSubdirectory() {
        let scenario = "scenario4_nested_basic"

        // Verify ModuleA's nested config doesn't affect ModuleB
        let scenarioPath = fixturePath(scenario)
        let config = Configuration(configurationFiles: [])

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleA/File.swift")
        )!
        let moduleBFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleB/File.swift")
        )!

        let moduleAConfig = config.configuration(for: moduleAFile)
        let moduleBConfig = config.configuration(for: moduleBFile)

        // ModuleA should have the nested config's opt-in rule
        XCTAssertTrue(
            moduleAConfig.rules.contains(where: { type(of: $0).identifier == "explicit_type_interface" })
        )

        // ModuleB should not have it (only root config)
        XCTAssertFalse(
            moduleBConfig.rules.contains(where: { type(of: $0).identifier == "explicit_type_interface" })
        )
    }

    func testNestedConfigurationDisabledByConfigFlag() {
        // When --config flag is used, nested configs should be ignored
        let scenarioPath = fixturePath("scenario5_nested_disabled_by_config_flag")
        let configFile = scenarioPath.stringByAppendingPathComponent("root.yml")
        let config = Configuration(configurationFiles: [configFile])

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleA/File.swift")
        )!

        let fileConfig = config.configuration(for: moduleAFile)

        // Should not have the opt-in rule from nested config
        XCTAssertFalse(
            fileConfig.rules.contains(where: { type(of: $0).identifier == "explicit_type_interface" })
        )
    }

    func testNestedConfigurationRuleApplication() {
        let scenarioPath = fixturePath("scenario4_nested_basic")

        // Save current directory and change to scenario path
        let previousDir = FileManager.default.currentDirectoryPath
        defer { _ = FileManager.default.changeCurrentDirectoryPath(previousDir) }

        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(scenarioPath))

        // Create config without explicit config file to enable nested config discovery
        let config = Configuration(configurationFiles: [])

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleA/File.swift")
        )!
        let moduleBFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleB/File.swift")
        )!

        let moduleAConfig = config.configuration(for: moduleAFile)
        let moduleBConfig = config.configuration(for: moduleBFile)

        // ModuleA should have the nested config's opt-in rule
        XCTAssertTrue(
            moduleAConfig.rules.contains { type(of: $0).identifier == "explicit_type_interface" }
        )

        // ModuleB should not have the opt-in rule (no nested config)
        XCTAssertFalse(
            moduleBConfig.rules.contains { type(of: $0).identifier == "explicit_type_interface" }
        )
    }

    // MARK: - Wildcard Pattern Tests

    func testWildcardPatternExclusion() {
        // Config excludes **/*.generated.swift
        // Expected: User.swift included, *.generated.swift files excluded

        let paths = lintableFilePaths(
            in: "scenario6_wildcard_patterns",
            configFile: "project/.swiftlint.yml",
            inPath: "project"
        )
        XCTAssertEqual(paths, ["project/Sources/Models/User.swift"])
    }

    func testWildcardPatternCount() {
        let paths = lintableFilePaths(
            in: "scenario6_wildcard_patterns",
            configFile: "project/.swiftlint.yml",
            inPath: "project"
        )

        XCTAssertEqual(paths, ["project/Sources/Models/User.swift"])
    }

    // MARK: - Path Normalization Tests

    func testRelativePathsNormalizedAcrossDirectories() {
        // Parent in base/ references ../project/Sources
        // This tests that paths are correctly normalized to absolute, then back to relative

        let scenarioPath = fixturePath("scenario2_parent_child_different_dirs")
        let configFile = scenarioPath.stringByAppendingPathComponent("project/.swiftlint.yml")
        let config = Configuration(configurationFiles: [configFile])

        // Verify the config loaded successfully with parent reference
        XCTAssertNotNil(config)

        // Verify that the merged included paths work correctly
        let files = config.lintableFiles(
            inPath: scenarioPath.stringByAppendingPathComponent("project"),
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths())
        )
        let relativePaths = files.map { $0.path!.bridge().path(relativeTo: scenarioPath) }.sorted()

        XCTAssertEqual(relativePaths, ["project/Sources/Core/Service.swift"])
    }

    func testExcludedPathsRespectConfigLocation() {
        let scenarioPath = fixturePath("scenario2_parent_child_different_dirs")

        // Child config's "Sources/Generated" should be relative to project/
        let configFile = scenarioPath.stringByAppendingPathComponent("project/.swiftlint.yml")
        let config = Configuration(configurationFiles: [configFile])

        let files = config.lintableFiles(
            inPath: scenarioPath.stringByAppendingPathComponent("project"),
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths())
        )
        let relativePaths = files.map { $0.path!.bridge().path(relativeTo: scenarioPath) }.sorted()

        // Generated should be excluded relative to project directory
        XCTAssertEqual(relativePaths, ["project/Sources/Core/Service.swift"])
    }

    // MARK: - Edge Cases

    func testEmptyIncludedDefaultsToAll() {
        // Use a config file that has excluded paths but no included paths
        let scenarioPath = fixturePath("scenario1_parent_child_same_dir")

        // Create a minimal config with just excluded paths
        let config = Configuration(
            includedPaths: [],
            excludedPaths: [scenarioPath.stringByAppendingPathComponent("Sources/Generated")]
        )

        let files = config.lintableFiles(
            inPath: scenarioPath,
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths())
        )
        let relativePaths = files.map { $0.path!.bridge().path(relativeTo: scenarioPath) }.sorted()

        XCTAssertEqual(relativePaths, [
            "Sources/CoreFile.swift",
            "Sources/Models/Model.swift",
        ])
    }

    func testMultipleLevelsOfExclusion() {
        let paths = lintableFilePaths(in: "scenario1_parent_child_same_dir", configFile: "parent.yml")

        XCTAssertEqual(paths, ["Sources/CoreFile.swift"])
        // Parent excludes Sources/Generated
        XCTAssertFalse(paths.contains("Sources/Generated/GeneratedFile.swift"))
        // Child excludes Sources/Models
        XCTAssertFalse(paths.contains("Sources/Models/Model.swift"))
    }
}
