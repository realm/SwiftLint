import ArgumentParser
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
        @Option(help: "Run only the specified rule, ignoring `only_rules`, `opt_in_rules` and `disabled_rules`.")
        var onlyRule: String?
        @Argument(help: pathsArgumentDescription(for: .analyze))
        var paths = [String]()

        func run() async throws {
            // Analyze files in current working directory if no paths were specified.
            let allPaths = paths.isNotEmpty ? paths : [""]
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
                baseline: common.baseline,
                writeBaseline: common.writeBaseline,
                workingDirectory: common.workingDirectory,
                quiet: quiet,
                output: common.output,
                progress: common.progress,
                cachePath: nil,
                ignoreCache: true,
                enableAllRules: false,
                onlyRule: onlyRule,
                autocorrect: common.fix,
                format: common.format,
                compilerLogPath: compilerLogPath,
                compileCommands: compileCommands,
                inProcessSourcekit: common.inProcessSourcekit,
                checkForUpdates: common.checkForUpdates
            )

            try await LintOrAnalyzeCommand.run(options)
        }
    }
}
