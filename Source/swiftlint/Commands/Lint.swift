import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Lint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Print lint warnings and errors")

        @OptionGroup
        var common: LintOrAnalyzeArguments
        @Flag(help: "Lint standard input.")
        var useSTDIN = false
        @Flag(help: quietOptionDescription(for: .lint))
        var quiet = false
        @Flag(help: "Don't print deprecation warnings.")
        var silenceDeprecationWarnings = false
        @Option(help: "The directory of the cache used when linting.")
        var cachePath: String?
        @Flag(help: "Ignore cache when linting.")
        var noCache = false
        @Flag(help: "Run all rules, even opt-in and disabled ones, ignoring `only_rules`.")
        var enableAllRules = false
        @Argument(help: pathsArgumentDescription(for: .lint))
        var paths = [String]()

        func run() async throws {
            Issue.printDeprecationWarnings = !silenceDeprecationWarnings

            if common.fix, let leniency = common.leniency {
                Issue.genericWarning("The option --\(leniency) has no effect together with --fix.").print()
            }

            // Lint files in current working directory if no paths were specified.
            let allPaths = paths.isNotEmpty ? paths : [""]
            let options = LintOrAnalyzeOptions(
                mode: .lint,
                paths: allPaths,
                useSTDIN: useSTDIN,
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
                quiet: quiet,
                output: common.output,
                progress: common.progress,
                cachePath: cachePath,
                ignoreCache: noCache,
                enableAllRules: enableAllRules,
                autocorrect: common.fix,
                format: common.format,
                compilerLogPath: nil,
                compileCommands: nil,
                inProcessSourcekit: common.inProcessSourcekit
            )
            try await LintOrAnalyzeCommand.run(options)
        }
    }
}
