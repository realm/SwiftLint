import Foundation
import PackagePlugin

@main
struct SwiftLintCommandPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "swiftlint")
        guard !arguments.contains("--cache-path") else {
            Diagnostics.error("Caching is managed by the plugin and so setting `--cache-path` is not allowed")
            return
        }
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = if arguments.contains("analyze") {
                                // The analyze command does not support the `--cache-path` argument.
                                arguments
                            } else {
                                arguments + ["--cache-path", "\(context.pluginWorkDirectory.string)"]
                            }

        try process.run()
        process.waitUntilExit()
        switch process.terminationReason {
        case .exit:
            break
        case .uncaughtSignal:
            Diagnostics.error("Uncaught signal")
        @unknown default:
            Diagnostics.error("Unexpected termination reason")
        }
        if process.terminationStatus != EXIT_SUCCESS {
            Diagnostics.warning("Command found violations or failed to execute")
        }
    }
}
