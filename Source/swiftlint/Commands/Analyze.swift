import ArgumentParser

extension SwiftLint {
    struct Analyze: ParsableCommand {
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

        mutating func run() throws {
            let options = LintOrAnalyzeOptions(
                mode: .analyze,
                paths: paths + [path ?? ""],
                useSTDIN: false,
                configurationFiles: common.config,
                strict: common.strict,
                lenient: common.lenient,
                forceExclude: common.forceExclude,
                useExcludingByPrefix: common.useAlternativeExcluding,
                useScriptInputFiles: common.useScriptInputFiles,
                benchmark: common.benchmark,
                reporter: common.reporter,
                quiet: quiet,
                cachePath: nil,
                ignoreCache: true,
                enableAllRules: false,
                autocorrect: common.fix,
                compilerLogPath: compilerLogPath,
                compileCommands: compileCommands
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
