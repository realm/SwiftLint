import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        [
            .buildCommand(
                displayName: "SwiftLint",
                executable: try context.tool(named: "swiftlint").path,
                arguments: []
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintPlugin: XcodeBuildToolPlugin {

    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        [
            .buildCommand(
                displayName: "SwiftLint",
                executable: try context.tool(named: "swiftlint").path,
                arguments: []
            )
        ]
    }
}
#endif
