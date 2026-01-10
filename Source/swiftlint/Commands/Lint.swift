import ArgumentParser
import Foundation
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
        @Flag(
            name: .customLong("disable-sourcekit"),
            help: "Do not dynamically load SourceKit at runtime. Skip and report rules that require it."
        )
        var disableSourceKit = false
        @Argument(help: pathsArgumentDescription(for: .lint))
        var paths = [URL]()

        func run() async throws {
            Issue.printDeprecationWarnings = !silenceDeprecationWarnings

            if common.fix, let leniency = common.leniency {
                Issue.genericWarning("The option --\(leniency) has no effect together with --fix.").print()
            }

            // Lint files in current working directory if no paths were specified.
            let allPaths = paths.isNotEmpty ? paths : [URL.cwd]
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
                useScriptInputFileLists: common.useScriptInputFileLists,
                benchmark: common.benchmark,
                reporter: common.reporter,
                baseline: common.baseline,
                writeBaseline: common.writeBaseline,
                workingDirectory: common.workingDirectory,
                quiet: quiet,
                output: common.output,
                progress: common.progress,
                cachePath: cachePath,
                ignoreCache: noCache,
                enableAllRules: enableAllRules,
                onlyRule: common.onlyRule,
                autocorrect: common.fix,
                format: common.format,
                disableSourceKit: disableSourceKit,
                compilerLogPath: nil,
                compileCommands: nil,
                checkForUpdates: common.checkForUpdates
            )
            try await LintOrAnalyzeCommand.run(options)
        }
    }
}
