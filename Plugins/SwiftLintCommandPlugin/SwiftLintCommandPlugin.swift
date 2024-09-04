import Foundation
import PackagePlugin

@main
struct SwiftLintCommandPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        guard !arguments.contains("--cache-path") else {
            Diagnostics.error("Caching is managed by the plugin and so setting `--cache-path` is not allowed")
            return
        }
        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targets = targetNames.isEmpty
            ? context.package.targets
            : try context.package.targets(named: targetNames)
        let tool = try context.tool(named: "swiftlint")
        for target in targets {
            guard let target = target.sourceModule else {
                Diagnostics.warning("Target '\(target.name)' is not a source module; skipping it")
                continue
            }

            let process = Process()
            process.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)
            process.executableURL = URL(fileURLWithPath: tool.path.string)
            process.arguments = arguments
            if !arguments.contains("analyze") {
                // The analyze command does not support the `--cache-path` argument.
                process.arguments! += ["--cache-path", "\(context.pluginWorkDirectory.string)"]
            }
            process.arguments! += [target.directory.string]

            try process.run()
            process.waitUntilExit()

            switch process.terminationReason {
            case .exit:
                Diagnostics.remark("Finished running in module '\(target.name)'")
            case .uncaughtSignal:
                Diagnostics.error("Got uncaught signal while running in module '\(target.name)'")
            @unknown default:
                Diagnostics.error("Stopped running in module '\(target.name) due to unexpected termination reason")
            }

            if process.terminationStatus != EXIT_SUCCESS {
                Diagnostics.error(
                    "Command found violations or unsuccessfully stopped running in module '\(target.name)' / Exit code: '\(process.terminationStatus)'"
                )
            }
        }
    }
}
