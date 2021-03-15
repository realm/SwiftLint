import ArgumentParser

extension SwiftLint {
    struct Lint: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Print lint warnings and errors")

        @OptionGroup
        var common: LintOrAnalyzeArguments
        @Option(help: pathOptionDescription(for: .lint))
        var path: String?
        @Flag(help: "Lint standard input.")
        var useSTDIN = false
        @Flag(help: quietOptionDescription(for: .lint))
        var quiet = false
        @Option(help: "The directory of the cache used when linting.")
        var cachePath: String?
        @Flag(help: "Ignore cache when linting.")
        var noCache = false
        @Flag(help: "Run all rules, even opt-in and disabled ones, ignoring `only_rules`.")
        var enableAllRules = false
        @Argument(help: pathsArgumentDescription(for: .lint))
        var paths = [String]()

        mutating func run() throws {
            let allPaths: [String]
            if let path = path {
                allPaths = [path]
            } else if !paths.isEmpty {
                allPaths = paths
            } else {
                allPaths = [""] // Lint files in current working directory if no paths were specified.
            }
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
                quiet: quiet,
                cachePath: cachePath,
                ignoreCache: noCache,
                enableAllRules: enableAllRules,
                autocorrect: common.fix,
                format: common.format,
                compilerLogPath: nil,
                compileCommands: nil
            )
            let result = LintOrAnalyzeCommand.run(options)
            switch result {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }
}
