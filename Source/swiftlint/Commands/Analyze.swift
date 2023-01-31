import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Analyze: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Run analysis rules")

        @OptionGroup
        var common: LintOrAnalyzeArguments
        @Option(help: pathOptionDescription(for: .analyze))
        var path: String?
        @Flag(help: quietOptionDescription(for: .analyze))
        var quiet = false
        @Option(help: "The path of the full xcodebuild log to use when running AnalyzerRules.")
        var compilerLogPath: String?
        @Option(help: "The path of a compilation database to use when running AnalyzerRules.")
        var compileCommands: String?
        @Argument(help: pathsArgumentDescription(for: .analyze))
        var paths = [String]()

        func run() async throws {
            let allPaths: [String]
            if let path {
                queuedPrintError("""
                    warning: The --path option is deprecated. Pass the path(s) to analyze last to the swiftlint command.
                    """)
                allPaths = [path] + paths
            } else if !paths.isEmpty {
                allPaths = paths
            } else {
                allPaths = [""] // Analyze files in current working directory if no paths were specified.
            }
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
                benchmark: common.benchmark,
                reporter: common.reporter,
                quiet: quiet,
                output: common.output,
                progress: common.progress,
                cachePath: nil,
                ignoreCache: true,
                enableAllRules: false,
                autocorrect: common.fix,
                format: common.format,
                compilerLogPath: compilerLogPath,
                compileCommands: compileCommands,
                inProcessSourcekit: common.inProcessSourcekit
            )

            try await LintOrAnalyzeCommand.run(options)
        }
    }
}
