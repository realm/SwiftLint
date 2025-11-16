import SourceKittenFramework
import SwiftLintFramework
import TestHelpers
import XCTest

final class ConfigPathResolutionTests: SwiftLintTestCase {
    private func fixturePath(_ scenario: String) -> String {
        #filePath.bridge()
            .deletingLastPathComponent
            .stringByAppendingPathComponent("Resources")
            .stringByAppendingPathComponent(scenario)
    }

    /// Returns the paths of lintable files relative to the fixture directory.
    private func lintableFilePaths(in scenario: String, configFile: String? = nil, inPath: String = ".") -> [String] {
        let scenarioPath = fixturePath(scenario)

        let previousDir = FileManager.default.currentDirectoryPath
        defer {
            _ = FileManager.default.changeCurrentDirectoryPath(previousDir)
        }
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(scenarioPath))

        let config = Configuration(configurationFiles: configFile.map { [$0] } ?? [])
        let files = config.lintableFiles(
            inPath: inPath,
            forceExclude: false,
            excludeByPrefix: false
        )

        return files.map { $0.path!.bridge().path(relativeTo: scenarioPath) }.sorted()
    }

    func testParentChildSameDirectory() {
        XCTAssertEqual(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml"),
            ["Sources/CoreFile.swift"]
        )
    }

    func testParentChildDifferentDirectories() {
        XCTAssertEqual(
            lintableFilePaths(
                in: "_2_parent_child_different_dirs",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ),
            ["project/Sources/Core/Service.swift"]
        )
    }

    func testChildOverridesParentExclusion() {
        XCTAssertEqual(
            lintableFilePaths(
                in: "_3_child_overrides_parent_exclusion",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ),
            ["project/Vendor/Critical/Important.swift"]
        )
    }

    func testParentIncludesChildExcludes() {
        XCTAssertEqual(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml"),
            ["Sources/CoreFile.swift"]
        )
    }

    func testNestedConfigurationBasic() {
        XCTAssertEqual(
            lintableFilePaths(in: "_4_nested_basic", configFile: ".swiftlint.yml"),
            ["ModuleA/File.swift", "ModuleA/Generated/File.swift", "ModuleB/File.swift"]
        )
    }

    func testWildcardPatternCount() {
        XCTAssertEqual(
            lintableFilePaths(
                in: "_5_wildcard_patterns",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ),
            ["project/Sources/Models/User.swift"]
        )
    }

    func testLintChildFolder() {
        XCTAssertEqual(
            lintableFilePaths(
                in: "_2_parent_child_different_dirs",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ),
            ["project/Sources/Core/Service.swift"]
        )
    }

    func testEmptyIncludedDefaultsToAll() {
        XCTAssertEqual(
            lintableFilePaths(
                in: "_6_wildcards_from_nested_folder",
                configFile: ".swiftlint-exclude-thirdparty.yml"
            ),
            [
                "Generated/API.swift",
                "MyProject/Package.swift",
                "MyProject/Sources/App.swift",
                "MyProject/SubModule/Package.swift",
            ]
        )
    }

    func testMultipleLevelsOfExclusion() {
        XCTAssertEqual(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml"),
            ["Sources/CoreFile.swift"]
        )
    }

    func testConfigFromParentFolder() {
        XCTAssertEqual(
            lintableFilePaths(in: "_6_wildcards_from_nested_folder", configFile: ".swiftlint.yml"),
            ["MyProject/Sources/App.swift"]
        )

        XCTAssertEqual(
            lintableFilePaths(in: "_6_wildcards_from_nested_folder/MyProject", configFile: "../.swiftlint.yml"),
            ["Sources/App.swift"]
        )
    }

    func testNestedConfigurationAppliesOnlyToSubdirectory() {
        let scenarioPath = fixturePath("_4_nested_basic")
        let config = Configuration(configurationFiles: [])

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleA/File.swift")
        )!
        let moduleBFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleB/File.swift")
        )!

        XCTAssertTrue(
            config.configuration(for: moduleAFile).rules
                .map { type(of: $0).identifier }
                .contains("explicit_type_interface")
        )

        XCTAssertFalse(
            config.configuration(for: moduleBFile).rules
                .map { type(of: $0).identifier }
                .contains("explicit_type_interface")
        )
    }

    func testNestedConfigurationDisabledByConfigFlag() {
        let scenarioPath = fixturePath("_4_nested_basic")
        let configFile = scenarioPath.stringByAppendingPathComponent("root.yml")

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.stringByAppendingPathComponent("ModuleB/File.swift")
        )!

        XCTAssertFalse(
            Configuration(configurationFiles: [configFile]).configuration(for: moduleAFile).rules
                .map { type(of: $0).identifier }
                .contains("explicit_type_interface")
        )
    }
}
