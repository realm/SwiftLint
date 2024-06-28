import Foundation
import PackagePlugin

@main
struct SwiftLintBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        try makeCommand(executable: context.tool(named: "swiftlint"),
                        swiftFiles: (target as? SourceModuleTarget).flatMap(swiftFiles) ?? [],
                        environment: environment(context: context, target: target),
                        pluginWorkDirectory: context.pluginWorkDirectory)
    }

    /// Collects the paths of the Swift files to be linted.
    private func swiftFiles(target: SourceModuleTarget) -> [Path] {
        target
            .sourceFiles(withSuffix: "swift")
            .map(\.path)
    }

    /// Creates an environment dictionary containing a value for the `BUILD_WORKSPACE_DIRECTORY` key.
    ///
    /// This method locates the topmost `.swiftlint.yml` config file within the package directory for this target
    /// and sets the config file's containing directory as the `BUILD_WORKSPACE_DIRECTORY` value. The package
    /// directory is used if a config file is not found.
    ///
    /// The `BUILD_WORKSPACE_DIRECTORY` environment variable controls SwiftLint's working directory.
    ///
    /// Reference: [https://github.com/realm/SwiftLint/blob/0.50.3/Source/swiftlint/Commands/SwiftLint.swift#L7](
    /// https://github.com/realm/SwiftLint/blob/0.50.3/Source/swiftlint/Commands/SwiftLint.swift#L7
    /// )
    private func environment(
        context: PluginContext,
        target: Target
    ) throws -> [String: String] {
        let workingDirectory: Path = try target.directory.resolveWorkingDirectory(in: context.package.directory)
        return ["BUILD_WORKSPACE_DIRECTORY": "\(workingDirectory)"]
    }

    private func makeCommand(
        executable: PluginContext.Tool,
        swiftFiles: [Path],
        environment: [String: String],
        pluginWorkDirectory path: Path
    ) throws -> [Command] {
        // Don't lint anything if there are no Swift source files in this target
        guard !swiftFiles.isEmpty else {
            return []
        }
        // Outputs the environment to the build log for reference.
        print("Environment:", environment)
        let arguments: [String] = [
            "lint",
            "--quiet",
            // We always pass all of the Swift source files in the target to the tool,
            // so we need to ensure that any exclusion rules in the configuration are
            // respected.
            "--force-exclude",
        ]
        // Determine whether we need to enable cache or not (for Xcode Cloud we don't)
        let cacheArguments: [String]
        if ProcessInfo.processInfo.environment["CI_XCODE_CLOUD"] == "TRUE" {
            cacheArguments = ["--no-cache"]
        } else {
            let cachePath: Path = path.appending("Cache")
            try FileManager.default.createDirectory(atPath: cachePath.string, withIntermediateDirectories: true)
            cacheArguments = ["--cache-path", "\(cachePath)"]
        }
        let outputPath: Path = path.appending("Output")
        try FileManager.default.createDirectory(atPath: outputPath.string, withIntermediateDirectories: true)
        return [
            .prebuildCommand(
                displayName: "SwiftLint",
                executable: executable.path,
                arguments: arguments + cacheArguments + swiftFiles.map(\.string),
                environment: environment,
                outputFilesDirectory: outputPath),
        ]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

// swiftlint:disable:next no_grouping_extension
extension SwiftLintBuildToolPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        try makeCommand(executable: context.tool(named: "swiftlint"),
                        swiftFiles: swiftFiles(target: target),
                        environment: environment(context: context, target: target),
                        pluginWorkDirectory: context.pluginWorkDirectory)
    }

    /// Collects the paths of the Swift files to be linted.
    private func swiftFiles(target: XcodeTarget) -> [Path] {
        target
            .inputFiles
            .filter { $0.type == .source && $0.path.extension == "swift" }
            .map(\.path)
    }

    /// Creates an environment dictionary containing a value for the `BUILD_WORKSPACE_DIRECTORY` key.
    ///
    /// This method locates the topmost `.swiftlint.yml` config file within the project directory for this target's
    /// Swift source files and sets the config file's containing directory as the `BUILD_WORKSPACE_DIRECTORY` value.
    /// The project directory is used if a config file is not found.
    ///
    /// The `BUILD_WORKSPACE_DIRECTORY` environment variable controls SwiftLint's working directory.
    ///
    /// Reference: [https://github.com/realm/SwiftLint/blob/0.50.3/Source/swiftlint/Commands/SwiftLint.swift#L7](
    /// https://github.com/realm/SwiftLint/blob/0.50.3/Source/swiftlint/Commands/SwiftLint.swift#L7
    /// )
    private func environment(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [String: String] {
        let projectDirectory: Path = context.xcodeProject.directory
        let swiftFiles: [Path] = swiftFiles(target: target)
        let swiftFilesNotInProjectDirectory: [Path] = swiftFiles.filter { !$0.isDescendant(of: projectDirectory) }

        guard swiftFilesNotInProjectDirectory.isEmpty else {
            throw SwiftLintBuildToolPluginError.swiftFilesNotInProjectDirectory(projectDirectory)
        }

        let directories: [Path] = try swiftFiles.map { try $0.resolveWorkingDirectory(in: projectDirectory) }
        let workingDirectory: Path = directories.min { $0.depth < $1.depth } ?? projectDirectory
        let swiftFilesNotInWorkingDirectory: [Path] = swiftFiles.filter { !$0.isDescendant(of: workingDirectory) }

        guard swiftFilesNotInWorkingDirectory.isEmpty else {
            throw SwiftLintBuildToolPluginError.swiftFilesNotInWorkingDirectory(workingDirectory)
        }

        return ["BUILD_WORKSPACE_DIRECTORY": "\(workingDirectory)"]
    }
}

#endif
