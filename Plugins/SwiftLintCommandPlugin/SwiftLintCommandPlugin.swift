import Foundation
import PackagePlugin

private let commandsNotExpectingPaths: Set<String> = [
    "docs",
    "generate-docs",
    "baseline",
    "reporters",
    "rules",
    "version",
]

private let commandsWithoutCachPathOption: Set<String> = commandsNotExpectingPaths.union([
    "analyze",
])

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
        guard !targets.isEmpty else {
            try run(with: context, arguments: arguments)
            return
        }
        for target in targets {
            guard let target = target.sourceModule else {
                Diagnostics.warning("Target '\(target.name)' is not a source module; skipping it")
                continue
            }
            try run(in: target.directory.string, for: target.name, with: context, arguments: arguments)
        }
    }

    private func run(in directory: String = ".",
                     for targetName: String? = nil,
                     with context: PluginContext,
                     arguments: [String]) throws {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)
        process.executableURL = URL(fileURLWithPath: try context.tool(named: "swiftlint").path.string)
        process.arguments = arguments
        if commandsWithoutCachPathOption.isDisjoint(with: arguments) {
            process.arguments! += ["--cache-path", "\(context.pluginWorkDirectory.string)"]
        }
        if commandsNotExpectingPaths.isDisjoint(with: arguments) {
            process.arguments! += [directory]
        }

        try process.run()
        process.waitUntilExit()

        let module = targetName.map { "module '\($0)'" } ?? "package"
        switch process.terminationReason {
        case .exit:
            Diagnostics.remark("Finished running in \(module)")
        case .uncaughtSignal:
            Diagnostics.error("Got uncaught signal while running in \(module)")
        @unknown default:
            Diagnostics.error("Stopped running in \(module) due to unexpected termination reason")
        }

        if process.terminationStatus != EXIT_SUCCESS {
            Diagnostics.error("""
                Command found error violations or unsuccessfully stopped running with \
                exit code \(process.terminationStatus) in \(module)
                """
            )
        }
    }
}
