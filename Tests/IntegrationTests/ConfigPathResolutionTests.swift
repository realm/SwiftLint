import SourceKittenFramework
import SwiftLintFramework
import TestHelpers
import XCTest

@testable import SwiftLintCore

final class ConfigPathResolutionTests: SwiftLintTestCase, @unchecked Sendable {
    private func fixturePath(_ scenario: String) -> URL {
        #filePath.url(directoryHint: .isDirectory)
            .deletingLastPathComponent()
            .appending(path: "Resources", directoryHint: .isDirectory)
            .appending(path: scenario, directoryHint: .isDirectory)
    }

    /// Returns the paths of lintable files relative to the fixture directory.
    private func lintableFilePaths(in scenario: String, configFile: String? = nil, inPath: String? = nil) -> [String] {
        let scenarioPath = fixturePath(scenario)

        let previousDir = FileManager.default.currentDirectoryPath
        defer { _ = FileManager.default.changeCurrentDirectoryPath(previousDir) }
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(scenarioPath.filepath))

        let config = Configuration(configurationFiles: configFile.map { [$0.url()] } ?? [])
        let files = config.lintableFiles(
            inPath: inPath.map { $0.url() } ?? URL.cwd,
            forceExclude: false,
            excludeByPrefix: false
        )

        return files.map { $0.path!.relativeFilepath }.sorted()
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
            path: scenarioPath.appending(path: "ModuleA/File.swift")
        )!
        let moduleBFile = SwiftLintFile(
            path: scenarioPath.appending(path: "ModuleB/File.swift")
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

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.appending(path: "ModuleB/File.swift")
        )!

        XCTAssertFalse(
            Configuration(configurationFiles: [scenarioPath.appending(path: "root.yml")])
                .configuration(for: moduleAFile)
                .rules
                .map { type(of: $0).identifier }
                .contains("explicit_type_interface")
        )
    }

    #if !os(Windows)
    func testUnicodePrivateUseAreaCharacterInPath() async throws {
        let fixture = fixturePath("_8_unicode_private_use_area")

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
        process.arguments = ["unzip", "-o", fixture.appending(path: "app.zip").filepath, "-d", fixture.filepath]
        try process.run()
        process.waitUntilExit()
        defer { try? FileManager.default.removeItem(at: fixture.appending(path: "App")) }

        if #available(macOS 26, *) {
            XCTAssertEqual(
                lintableFilePaths(in: "_8_unicode_private_use_area/App"),
                ["Resources/Settings.bundle/androidx.core:core-bundle.swift"]
            )
        } else {
            let console = await Issue.captureConsole {
                XCTAssert(lintableFilePaths(in: "_8_unicode_private_use_area/App").isEmpty)
            }
            XCTAssert(
                console.contains(
                    """
                    error: File with URL 'androidx.core:core-bundle.swift' \
                    cannot be represented as a file system path; skipping it
                    """
                )
            )
        }
    }
    #endif
}
