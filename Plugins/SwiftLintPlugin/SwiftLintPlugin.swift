import Foundation
import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let inputFilePaths = sourceTarget.sourceFiles(withSuffix: "swift")
            .map(\.path)

        guard inputFilePaths.isEmpty == false else {
            // Don't lint anything if there are no Swift source files in this target
            return []
        }

        let swiftlint = try context.tool(named: "swiftlint")
        var arguments: [String] = [
            "lint",
            "--cache-path", "\(context.pluginWorkDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the package source directory.
        if let configuration = context.package.directory.firstConfigurationFileInParentDirectories() {
            arguments.append(contentsOf: [
                "--config", "\(configuration.string)"
            ])
        }

        arguments += inputFilePaths.map(\.string)

        return [
            .buildCommand(
                displayName: "SwiftLint",
                executable: swiftlint.path,
                arguments: arguments,
                inputFiles: inputFilePaths,
                outputFiles: [context.pluginWorkDirectory]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let inputFilePaths = target.inputFiles
            .filter { $0.type == .source && $0.path.extension == "swift" }
            .map(\.path)

        guard inputFilePaths.isEmpty == false else {
            // Don't lint anything if there are no Swift source files in this target
            return []
        }

        let swiftlint = try context.tool(named: "swiftlint")
        var arguments: [String] = [
            "lint",
            "--cache-path", "\(context.pluginWorkDirectory)"
        ]

        // Xcode build tool plugins don't seem to run from the project source directory, so our auto-discovery of configuration files doesn't work. We approximate it here.
        if let configuration = context.xcodeProject.directory.firstConfigurationFileInParentDirectories() {
            arguments.append(contentsOf: [
                "--config", "\(configuration.string)"
            ])
        }

        arguments += inputFilePaths.map(\.string)

        return [
            .buildCommand(
                displayName: "SwiftLint",
                executable: swiftlint.path,
                arguments: arguments,
                inputFiles: inputFilePaths,
                outputFiles: [context.pluginWorkDirectory]
            )
        ]
    }
}
#endif

private extension Path {
    /// Scans the receiver, then all of it's parents looking for a configuration file with the name ".swiftlint.yml".
    /// - Returns: Path to the configuration file, or nil if one cannot be found.
    func firstConfigurationFileInParentDirectories() -> Path? {
        // TODO: Consider linking to the framework to get the default configuration file name
        let defaultConfigurationFileName = ".swiftlint.yml"
        let proposedDirectory = sequence(first: self, next: { $0.removingLastComponent() })
            .first { path in
                let potentialConfigurationFile = path.appending(subpath: defaultConfigurationFileName)
                return FileManager.default.isReadableFile(atPath: potentialConfigurationFile.string)
            }

        return proposedDirectory?.appending(subpath: defaultConfigurationFileName)
    }
}
