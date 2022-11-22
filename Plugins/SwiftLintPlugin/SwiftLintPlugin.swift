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

        let swiftlint = try context.tool(named: "swiftlint")
        var arguments: [String] = [
            "lint",
            "--cache-path", "\(context.pluginWorkDirectory)"
        ]

        let inputFilePaths = sourceTarget.sourceFiles(withSuffix: "swift").map(\.path)

        guard inputFilePaths.isEmpty == false else {
            // Don't lint anything if there are no Swift source files in this target
            return []
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
