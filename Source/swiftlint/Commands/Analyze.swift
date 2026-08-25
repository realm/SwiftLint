import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct Analyze: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Run analysis rules")

        @OptionGroup
        var common: LintOrAnalyzeArguments
        @Flag(help: quietOptionDescription(for: .analyze))
        var quiet = false
        @Option(help: "The path of the full xcodebuild log to use when running AnalyzerRules.")
        var compilerLogPath: String?
        @Option(help: "The path of a compilation database to use when running AnalyzerRules.")
        var compileCommands: String?
        @Option(
            name: .customLong("target-plan"),
            help: "The versioned target plan for process-isolated analysis."
        )
        var targetPlan: URL?
        @Option(help: "The global worker-process limit used with --target-plan.")
        var jobs = 1
        @Option(
            name: .customLong("execution-evidence"),
            help: "The path where analyzer execution evidence should be written."
        )
        var executionEvidence: URL?
        @Argument(help: pathsArgumentDescription(for: .analyze))
        var paths = [URL]()

        func run() async throws {
            if let requestPath = ProcessInfo.processInfo.environment[AnalyzerWorkerEnvironment.requestPath] {
                try await LintOrAnalyzeCommand.runAnalyzerWorker(requestAt: URL(filePath: requestPath))
                return
            }

            // Analyze files in current working directory if no paths were specified.
            let allPaths = paths.isNotEmpty ? paths : [URL.cwd]
            let options = LintOrAnalyzeOptions(
                mode: .analyze,
                paths: allPaths,
                useSTDIN: false,
                configurationFiles: common.config,
                strict: common.leniency == .strict,
                lenient: common.leniency == .lenient,
                forceExclude: common.forceExclude,
                useExcludingByPrefix: common.useAlternativeExcluding,
                useScriptInputFiles: common.useScriptInputFiles,
                useScriptInputFileLists: common.useScriptInputFileLists,
                benchmark: common.benchmark,
                reporter: common.reporter,
                baseline: common.baseline,
                writeBaseline: common.writeBaseline,
                workingDirectory: common.workingDirectory,
                quiet: quiet,
                output: common.output,
                progress: common.progress,
                cachePath: nil,
                ignoreCache: true,
                enableAllRules: false,
                onlyRule: common.onlyRule,
                autocorrect: common.fix,
                format: common.format,
                disableSourceKit: false,
                compilerLogPath: compilerLogPath,
                compileCommands: compileCommands,
                checkForUpdates: common.checkForUpdates,
                targetPlan: targetPlan,
                analyzerJobs: jobs,
                executionEvidence: executionEvidence
            )

            try await LintOrAnalyzeCommand.run(options)
        }
    }
}
