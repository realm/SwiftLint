import PackagePlugin
import Foundation

@main
struct SwiftLintLinterPlugin {
    private func lint(
        in directories: [String],
        tool: PackagePlugin.PluginContext.Tool,
        configFile: String?
    ) throws {
        let swiftlintExec = URL(fileURLWithPath: tool.path.string)
        
        var swiftlintArgs = ["lint"]
        if let configFile {
            swiftlintArgs.append(contentsOf: ["--config", configFile])
        }
        swiftlintArgs.append(contentsOf: directories)
        
        let process = try Process.run(swiftlintExec, arguments: swiftlintArgs)
        process.waitUntilExit()
        
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Lintted the source code.")
        }
        else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("swiftlint invocation failed: \(problem)")
        }
    }
}

extension SwiftLintLinterPlugin: CommandPlugin {
    func performCommand(
        context: PackagePlugin.PluginContext,
        arguments: [String]
    ) async throws {
        var argExtractor = ArgumentExtractor(arguments)
        let selectedTargetNames = argExtractor.extractOption(named: "target")
        let targetDirectories = try context.package.targets(named: selectedTargetNames)
            .compactMap { $0 as? SourceModuleTarget }
            .map(\.directory.string)
        
        let swiftlintTool = try context.tool(named: "swiftlint")
        
        let configFile = argExtractor.extractOption(named: "config").first
        
        try lint(in: targetDirectories, tool: swiftlintTool, configFile: configFile)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintLinterPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodeProjectPlugin.XcodePluginContext,
        arguments: [String]
    ) throws {
        let swiftlintTool = try context.tool(named: "swiftlint")
        
        var argExtractor = ArgumentExtractor(arguments)
        let configFile = argExtractor.extractOption(named: "config").first
        
        try lint(
            in: [context.xcodeProject.directory.string],
            tool: swiftlintTool,
            configFile: configFile
        )
    }
}
#endif
