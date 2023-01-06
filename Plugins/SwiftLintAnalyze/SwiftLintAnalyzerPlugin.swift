import PackagePlugin
import Foundation

@main
struct SwiftLintAnalyzerPlugin {
    private func analyze(
        in directories: [String],
        tool: PackagePlugin.PluginContext.Tool,
        configFile: String?,
        isFix: Bool,
        compilerLogPath: String?
    ) throws {
        let swiftlintExec = URL(fileURLWithPath: tool.path.string)
        
        var swiftlintArgs = ["analyze"]
        if let configFile {
            swiftlintArgs.append(contentsOf: ["--config", configFile])
        }
        if isFix {
            swiftlintArgs.append("--fix")
        }
        if let compilerLogPath {
            swiftlintArgs.append(contentsOf: ["--compiler-log-path", compilerLogPath])
        }
        swiftlintArgs.append(contentsOf: directories)
        
        let process = try Process.run(swiftlintExec, arguments: swiftlintArgs)
        process.waitUntilExit()
        
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Analyzed the source code.")
        }
        else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("swiftlint invocation failed: \(problem)")
        }
    }
}

extension SwiftLintAnalyzerPlugin: CommandPlugin {
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
        let isFix = argExtractor.extractFlag(named: "fix") > 0
        let compilerLogPath = argExtractor.extractOption(named: "compiler-log-path").first
        
        try analyze(
            in: targetDirectories,
            tool: swiftlintTool,
            configFile: configFile,
            isFix: isFix,
            compilerLogPath: compilerLogPath
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintAnalyzerPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodeProjectPlugin.XcodePluginContext,
        arguments: [String]
    ) throws {
        let swiftlintTool = try context.tool(named: "swiftlint")
        
        var argExtractor = ArgumentExtractor(arguments)
        let configFile = argExtractor.extractOption(named: "config").first
        let isFix = argExtractor.extractFlag(named: "fix") > 0
        let compilerLogPath = argExtractor.extractOption(named: "compiler-log-path").first
        
        try analyze(
            in: [context.xcodeProject.directory.string],
            tool: swiftlintTool,
            configFile: configFile,
            isFix: isFix,
            compilerLogPath: compilerLogPath
        )
    }
}
#endif
