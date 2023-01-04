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
            "--quiet",
            "--cache-path", "\(context.pluginWorkDirectory)"
        ]

        // Manually look for configuration files, to avoid issues when the plugin does not execute our tool from the
        // package source directory.
        if let configuration = context.package.directory.firstConfigurationFileInParentDirectories() {
            arguments.append(contentsOf: [
                "--config", "\(configuration.string)"
            ])
        }

        arguments += inputFilePaths.map(\.string)

        // We are not producing output files and this is needed only to not include cache files into bundle
        let outputFilesDirectory = context.pluginWorkDirectory.appending("Output")

        return [
            .prebuildCommand(
                displayName: "SwiftLint",
                executable: swiftlint.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
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
            "--quiet",
            "--cache-path", "\(context.pluginWorkDirectory)"
        ]

        // Xcode build tool plugins don't seem to run from the project source directory, so our auto-discovery of
        // configuration files doesn't work. We approximate it here.
        if let configuration = context.xcodeProject.directory.firstConfigurationFileInParentDirectories() {
            arguments.append(contentsOf: [
                "--config", "\(configuration.string)"
            ])
        }

        arguments += inputFilePaths.map(\.string)

        // We are not producing output files and this is needed only to not include cache files into bundle
        let outputFilesDirectory = context.pluginWorkDirectory.appending("Output")

        return [
            .prebuildCommand(
                displayName: "SwiftLint",
                executable: swiftlint.path,
                arguments: arguments,
                outputFilesDirectory: outputFilesDirectory
            )
        ]
    }
}
#endif
