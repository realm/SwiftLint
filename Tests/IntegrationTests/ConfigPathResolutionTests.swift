import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintCore
@testable import SwiftLintFramework

@Suite(.rulesRegistered)
struct ConfigPathResolutionTests {
    private func fixturePath(_ scenario: String) -> URL {
        #filePath.url(directoryHint: .isDirectory)
            .deletingLastPathComponent()
            .appending(path: "Resources", directoryHint: .isDirectory)
            .appending(path: scenario, directoryHint: .isDirectory)
    }

    /// Returns the paths of lintable files relative to the fixture directory.
    private func lintableFilePaths(in scenario: String, configFile: String? = nil, inPath: String? = nil) -> [String] {
        let scenarioPath = fixturePath(scenario)
        return CurrentWorkingDirectory.$url.withValue(scenarioPath) {
            let config = Configuration(configurationFiles: configFile.map { [$0.url()] } ?? [])
            let files = config.lintableFiles(
                inPath: inPath.map { $0.url() } ?? URL.cwd,
                forceExclude: false,
                excludeByPrefix: false
            )

            return relativePaths(of: files, in: scenario)
        }
    }

    /// Returns the paths of the files that are actually linted when the given paths are passed as command line
    /// arguments, relative to the fixture directory.
    private func visitedLintableFilePaths(in scenario: String, paths: [String]) async throws -> [String] {
        let scenarioPath = fixturePath(scenario)
        return try await CurrentWorkingDirectory.$url.withValue(scenarioPath) {
            let config = Configuration(configurationFiles: [])
            let files = try await config.visitLintableFiles(
                // Lint files in the current working directory if no paths were specified, just like the command does.
                options: .lint(paths: paths.isEmpty ? [URL.cwd] : paths.map { $0.url() }),
                storage: RuleStorage(),
                visitorBlock: { _ in
                    // Only the set of visited files matters, not the violations found in them.
                }
            )

            return relativePaths(of: files, in: scenario)
        }
    }

    private func relativePaths(of files: [SwiftLintFile], in scenario: String) -> [String] {
        // swiftlint:disable:next force_try
        files.map { $0.path!.path.replacing(try! Regex(".+/\(scenario)/"), with: "") }.sorted()
    }

    @Test
    func parentChildSameDirectory() {
        #expect(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml") == ["Sources/CoreFile.swift"]
        )
    }

    @Test
    func parentChildDifferentDirectories() {
        #expect(
            lintableFilePaths(
                in: "_2_parent_child_different_dirs",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ) == ["project/Sources/Core/Service.swift"]
        )
    }

    @Test
    func childOverridesParentExclusion() {
        #expect(
            lintableFilePaths(
                in: "_3_child_overrides_parent_exclusion",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ) == ["project/Vendor/Critical/Important.swift"]
        )
    }

    @Test
    func parentIncludesChildExcludes() {
        #expect(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml") == ["Sources/CoreFile.swift"]
        )
    }

    @Test
    func nestedConfigurationBasic() {
        #expect(
            lintableFilePaths(in: "_4_nested_basic", configFile: ".swiftlint.yml")
                == ["ModuleA/File.swift", "ModuleA/Generated/File.swift", "ModuleB/File.swift"]
        )
    }

    @Test
    func nestedConfigurationBasicWithCommandLine() async throws {
        // `swiftlint --quiet --no-cache ModuleA/File.swift ModuleA/Generated/File.swift ModuleB/File.swift`
        #expect(
            try await visitedLintableFilePaths(
                in: "_4_nested_basic",
                paths: ["ModuleA/File.swift", "ModuleA/Generated/File.swift", "ModuleB/File.swift"]
            ) == ["ModuleA/File.swift", "ModuleB/File.swift"]
        )

        // `swiftlint --quiet --no-cache`
        #expect(
            try await visitedLintableFilePaths(in: "_4_nested_basic", paths: [])
                == ["ModuleA/File.swift", "ModuleB/File.swift"]
        )
    }

    @Test
    func wildcardPatternCount() {
        #expect(
            lintableFilePaths(
                in: "_5_wildcard_patterns",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ) == ["project/Sources/Models/User.swift"]
        )
    }

    @Test
    func wildCardPatternCountWithCommandLine() async throws {
        // `swiftlint --quiet --no-cache Sources/Models/User.swift Sources/Models/User.generated.swift`
        let visitedWithPaths = try await visitedLintableFilePaths(
            in: "_5_wildcard_patterns",
            paths: ["project/Sources/Models/User.swift", "project/Sources/Models/User.generated.swift"]
        )
        withKnownIssue("Wildcard patterns do not work as expected.") {
            #expect(
                visitedWithPaths == ["project/Sources/Models/User.swift"]
            )
        }

        // `swiftlint --quiet --no-cache`
        let visitedWithoutPaths = try await visitedLintableFilePaths(in: "_5_wildcard_patterns", paths: [])
        withKnownIssue("Wildcard patterns do not work as expected.") {
            #expect(
                visitedWithoutPaths == ["project/Sources/Models/User.swift"]
            )
        }
    }

    @Test
    func lintChildFolder() {
        #expect(
            lintableFilePaths(
                in: "_2_parent_child_different_dirs",
                configFile: "project/.swiftlint.yml",
                inPath: "project"
            ) == ["project/Sources/Core/Service.swift"]
        )
    }

    @Test
    func emptyIncludedDefaultsToAll() {
        #expect(
            lintableFilePaths(
                in: "_6_wildcards_from_nested_folder",
                configFile: ".swiftlint-exclude-thirdparty.yml"
            ) == [
                "Generated/API.swift",
                "MyProject/Package.swift",
                "MyProject/Sources/App.swift",
                "MyProject/SubModule/Package.swift",
            ]
        )
    }

    @Test
    func multipleLevelsOfExclusion() {
        #expect(
            lintableFilePaths(in: "_1_parent_child_same_dir", configFile: "parent.yml") == ["Sources/CoreFile.swift"]
        )
    }

    @Test
    func configFromParentFolder() {
        #expect(
            lintableFilePaths(in: "_6_wildcards_from_nested_folder", configFile: ".swiftlint.yml")
                == ["MyProject/Sources/App.swift"]
        )

        #expect(
            lintableFilePaths(in: "_6_wildcards_from_nested_folder/MyProject", configFile: "../.swiftlint.yml")
                == ["Sources/App.swift"]
        )
    }

    @Test
    func nestedConfigurationAppliesOnlyToSubdirectory() throws {
        let scenarioPath = fixturePath("_4_nested_basic")
        try CurrentWorkingDirectory.$url.withValue(scenarioPath) {
            let config = Configuration(configurationFiles: [])

            let moduleAFile = try #require(
                SwiftLintFile(path: scenarioPath.appending(path: "ModuleA/File.swift"))
            )
            let moduleBFile = try #require(
                SwiftLintFile(path: scenarioPath.appending(path: "ModuleB/File.swift"))
            )

            #expect(
                config.configuration(for: moduleAFile).rules
                    .map { type(of: $0).identifier }
                    .contains("explicit_type_interface")
            )

            #expect(
                !config.configuration(for: moduleBFile).rules
                    .map { type(of: $0).identifier }
                    .contains("explicit_type_interface")
            )
        }
    }

    @Test
    func nestedConfigurationDisabledByConfigFlag() {
        let scenarioPath = fixturePath("_4_nested_basic")

        let moduleAFile = SwiftLintFile(
            path: scenarioPath.appending(path: "ModuleB/File.swift")
        )!

        #expect(
            !Configuration(configurationFiles: [scenarioPath.appending(path: "root.yml")])
                .configuration(for: moduleAFile)
                .rules
                .map { type(of: $0).identifier }
                .contains("explicit_type_interface")
        )
    }

    #if !os(Windows)
    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SWIFTLINT_BAZEL_TEST"] == nil,
        "Bazel's sandboxed environment uses symlinks heavily breaking the fixture setup"
    ))
    func symlinkedFileAndFolderAreFollowed() throws {
        let expectedPaths = ["Real/Folder/Nested.swift", "Real/Target.swift"]

        // With symlinks
        #expect(lintableFilePaths(in: "_9_symlinked_paths", configFile: ".swiftlint.yml") == expectedPaths)

        let fixture = fixturePath("_9_symlinked_paths")
        let fileLink = fixture.appending(path: "LinkToFile.swift", directoryHint: .notDirectory)
        var folderLink = fixture.appending(path: "LinkToFolder", directoryHint: .isDirectory)
        let targetFile = fixture.appending(path: "Real/Target.swift", directoryHint: .notDirectory)
        let targetFolder = fixture.appending(path: "Real/Folder", directoryHint: .isDirectory)

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: fileLink.filepath))
        #expect(fileManager.fileExists(atPath: folderLink.filepath))
        #expect(try fileLink.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
        #expect(try folderLink.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
        #expect(fileLink.resolvingSymlinksInPath() == targetFile)

        #expect(folderLink != targetFile)
        folderLink.resolveSymlinksInPath()
        #expect(try folderLink.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == false)
        #expect(folderLink == targetFolder)

        // Without symlinks
        #expect(lintableFilePaths(in: "_9_symlinked_paths", configFile: ".swiftlint.yml") == expectedPaths)
    }
    #endif

    #if !os(Windows)
    @Test
    func unicodePrivateUseAreaCharacterInPath() throws {
        let fixture = fixturePath("_8_unicode_private_use_area")

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
        process.arguments = ["unzip", "-o", fixture.appending(path: "app.zip").filepath, "-d", fixture.filepath]
        try process.run()
        process.waitUntilExit()
        defer { try? FileManager.default.removeItem(at: fixture.appending(path: "App")) }

        #expect(
            lintableFilePaths(in: "_8_unicode_private_use_area/App")
                == ["Resources/Settings.bundle/androidx.core:core-bundle.swift"]
        )
    }
    #endif
}

private extension LintOrAnalyzeOptions {
    /// Options equivalent to running `swiftlint lint --quiet --no-cache <paths>`.
    static func lint(paths: [URL]) -> Self {
        Self(
            mode: .lint,
            paths: paths,
            useSTDIN: false,
            configurationFiles: [],
            strict: false,
            lenient: false,
            forceExclude: false,
            useExcludingByPrefix: false,
            useScriptInputFiles: false,
            useScriptInputFileLists: false,
            benchmark: false,
            reporter: nil,
            baseline: nil,
            writeBaseline: nil,
            workingDirectory: nil,
            // Avoid verbose stderr.
            quiet: true,
            output: nil,
            progress: false,
            cachePath: nil,
            // `visitedLintableFilePaths` does not pass `LinterCache`.
            ignoreCache: true,
            enableAllRules: false,
            onlyRule: [],
            autocorrect: false,
            format: false,
            disableSourceKit: false,
            compilerLogPath: nil,
            compileCommands: nil,
            checkForUpdates: false
        )
    }
}
