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
        let remainingArguments = argExtractor.remainingArguments
        if targetNames.isEmpty || !commandsNotExpectingPaths.isDisjoint(with: remainingArguments) {
            try lintFiles(with: context, arguments: remainingArguments)
            return
        }
        for target in try context.targets(named: targetNames) {
            try lintFiles(in: target.path, for: target.name, with: context, arguments: remainingArguments)
        }
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension SwiftLintCommandPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var argExtractor = ArgumentExtractor(arguments)
        _ = argExtractor.extractOption(named: "target")

        try lintFiles(with: context, arguments: argExtractor.remainingArguments)
    }
}

#endif

private func lintFiles(in directory: String = ".",
                       for targetName: String? = nil,
                       with context: some CommandContext,
                       arguments: [String]) throws {
    let process = Process()
    process.currentDirectoryURL = URL(fileURLWithPath: context.workingDirectory)
    process.executableURL = URL(fileURLWithPath: try context.tool)
    process.arguments = arguments
    if commandsWithoutCachPathOption.isDisjoint(with: arguments) {
        process.arguments! += ["--cache-path", context.cacheDirectory]
    }
    if commandsNotExpectingPaths.isDisjoint(with: arguments) {
        process.arguments! += [directory]
    }

    try process.run()
    process.waitUntilExit()

    let module = targetName.map { "\(context.subUnitName) '\($0)'" } ?? context.unitName
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
